"""Trip, membership and invite tests.

The bulk of these are authorization tests: every endpoint is trip-scoped, so a
missing membership check would expose another group's data.
"""

from datetime import UTC, datetime, timedelta
from uuid import uuid4

from httpx import AsyncClient
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models import Invite, TripMember

TRIPS = "/api/v1/trips"


class TestCreateTrip:
    async def test_creates_and_returns_the_trip(self, client: AsyncClient, auth_headers: dict):
        response = await client.post(TRIPS, json={"name": "Lisbona"}, headers=auth_headers)
        assert response.status_code == 201
        assert response.json()["name"] == "Lisbona"

    async def test_creator_becomes_owner(self, client: AsyncClient, trip: dict, db: AsyncSession):
        """A trip without an owner would be unmanageable by anyone."""
        membership = await db.scalar(select(TripMember).where(TripMember.trip_id == trip["id"]))
        assert membership.role == "owner"

    async def test_requires_authentication(self, client: AsyncClient):
        assert (await client.post(TRIPS, json={"name": "X"})).status_code == 401

    async def test_rejects_reversed_dates(self, client: AsyncClient, auth_headers: dict):
        response = await client.post(
            TRIPS,
            json={"name": "X", "start_date": "2026-08-10", "end_date": "2026-08-01"},
            headers=auth_headers,
        )
        assert response.status_code == 422

    async def test_rejects_empty_name(self, client: AsyncClient, auth_headers: dict):
        response = await client.post(TRIPS, json={"name": ""}, headers=auth_headers)
        assert response.status_code == 422


class TestIsolation:
    """A stranger must not be able to tell that someone else's trip exists."""

    async def test_list_only_returns_own_trips(
        self, client: AsyncClient, trip: dict, other_headers: dict
    ):
        response = await client.get(TRIPS, headers=other_headers)
        assert response.json() == []

    async def test_reading_a_foreign_trip_returns_404_not_403(
        self, client: AsyncClient, trip: dict, other_headers: dict
    ):
        """403 would confirm the resource exists. 404 reveals nothing."""
        response = await client.get(f"{TRIPS}/{trip['id']}", headers=other_headers)
        assert response.status_code == 404

    async def test_patching_a_foreign_trip_returns_404(
        self, client: AsyncClient, trip: dict, other_headers: dict
    ):
        response = await client.patch(
            f"{TRIPS}/{trip['id']}", json={"name": "hijacked"}, headers=other_headers
        )
        assert response.status_code == 404

    async def test_deleting_a_foreign_trip_returns_404(
        self, client: AsyncClient, trip: dict, other_headers: dict
    ):
        response = await client.delete(f"{TRIPS}/{trip['id']}", headers=other_headers)
        assert response.status_code == 404

    async def test_listing_foreign_members_returns_404(
        self, client: AsyncClient, trip: dict, other_headers: dict
    ):
        response = await client.get(f"{TRIPS}/{trip['id']}/members", headers=other_headers)
        assert response.status_code == 404

    async def test_unknown_trip_id_returns_404(self, client: AsyncClient, auth_headers: dict):
        response = await client.get(f"{TRIPS}/{uuid4()}", headers=auth_headers)
        assert response.status_code == 404


class TestUpdate:
    async def test_owner_can_patch(self, client: AsyncClient, trip: dict, auth_headers: dict):
        response = await client.patch(
            f"{TRIPS}/{trip['id']}", json={"name": "Porto 2026"}, headers=auth_headers
        )
        assert response.status_code == 200
        assert response.json()["name"] == "Porto 2026"

    async def test_patch_leaves_untouched_fields_alone(
        self, client: AsyncClient, trip: dict, auth_headers: dict
    ):
        """Absent keys must not be blanked: that is the difference from PUT."""
        await client.patch(
            f"{TRIPS}/{trip['id']}",
            json={"description": "Con gli amici"},
            headers=auth_headers,
        )
        response = await client.patch(
            f"{TRIPS}/{trip['id']}", json={"name": "Porto"}, headers=auth_headers
        )
        assert response.json()["description"] == "Con gli amici"

    async def test_member_cannot_patch(
        self, client: AsyncClient, trip: dict, invite_code: str, other_headers: dict
    ):
        """Once joined the trip exists for them, so the answer becomes 403, not 404."""
        await client.post(f"{TRIPS}/join", json={"code": invite_code}, headers=other_headers)
        response = await client.patch(
            f"{TRIPS}/{trip['id']}", json={"name": "hijacked"}, headers=other_headers
        )
        assert response.status_code == 403


class TestInvites:
    async def test_owner_can_create_an_invite(
        self, client: AsyncClient, trip: dict, auth_headers: dict
    ):
        response = await client.post(f"{TRIPS}/{trip['id']}/invites", json={}, headers=auth_headers)
        assert response.status_code == 201
        assert len(response.json()["code"]) == 8

    async def test_code_avoids_ambiguous_characters(self, invite_code: str):
        """Codes get dictated out loud, so 0/O and 1/I must never appear."""
        assert not set(invite_code) & set("01OI")

    async def test_member_cannot_create_an_invite(
        self, client: AsyncClient, trip: dict, invite_code: str, other_headers: dict
    ):
        await client.post(f"{TRIPS}/join", json={"code": invite_code}, headers=other_headers)
        response = await client.post(
            f"{TRIPS}/{trip['id']}/invites", json={}, headers=other_headers
        )
        assert response.status_code == 403


class TestJoin:
    async def test_valid_code_grants_access(
        self, client: AsyncClient, trip: dict, invite_code: str, other_headers: dict
    ):
        joined = await client.post(
            f"{TRIPS}/join", json={"code": invite_code}, headers=other_headers
        )
        assert joined.status_code == 200
        assert joined.json()["id"] == trip["id"]

        readable = await client.get(f"{TRIPS}/{trip['id']}", headers=other_headers)
        assert readable.status_code == 200

    async def test_joining_twice_is_idempotent(
        self, client: AsyncClient, invite_code: str, other_headers: dict
    ):
        """Links get re-tapped in group chats; that must not error or burn a use."""
        await client.post(f"{TRIPS}/join", json={"code": invite_code}, headers=other_headers)
        second = await client.post(
            f"{TRIPS}/join", json={"code": invite_code}, headers=other_headers
        )
        assert second.status_code == 200

    async def test_unknown_code_is_rejected(self, client: AsyncClient, other_headers: dict):
        response = await client.post(
            f"{TRIPS}/join", json={"code": "ZZZZZZZZ"}, headers=other_headers
        )
        assert response.status_code == 400

    async def test_revoked_code_is_rejected(
        self, client: AsyncClient, trip: dict, auth_headers: dict, other_headers: dict
    ):
        created = await client.post(f"{TRIPS}/{trip['id']}/invites", json={}, headers=auth_headers)
        invite = created.json()
        await client.delete(f"{TRIPS}/{trip['id']}/invites/{invite['id']}", headers=auth_headers)
        response = await client.post(
            f"{TRIPS}/join", json={"code": invite["code"]}, headers=other_headers
        )
        assert response.status_code == 400

    async def test_expired_code_is_rejected(
        self,
        client: AsyncClient,
        trip: dict,
        auth_headers: dict,
        other_headers: dict,
        db: AsyncSession,
    ):
        created = await client.post(
            f"{TRIPS}/{trip['id']}/invites", json={"expires_in_hours": 1}, headers=auth_headers
        )
        code = created.json()["code"]

        # Rewind expiry instead of waiting an hour.
        invite = await db.scalar(select(Invite).where(Invite.code == code))
        invite.expires_at = datetime.now(UTC) - timedelta(minutes=1)
        await db.commit()

        response = await client.post(f"{TRIPS}/join", json={"code": code}, headers=other_headers)
        assert response.status_code == 400

    async def test_exhausted_code_is_rejected(
        self, client: AsyncClient, trip: dict, auth_headers: dict, other_headers: dict
    ):
        created = await client.post(
            f"{TRIPS}/{trip['id']}/invites", json={"max_uses": 1}, headers=auth_headers
        )
        code = created.json()["code"]
        await client.post(f"{TRIPS}/join", json={"code": code}, headers=other_headers)

        # A third account: the second one is already a member and would short-circuit.
        await client.post(
            "/api/v1/auth/register",
            json={"email": "anna@test.it", "password": "password123", "display_name": "Anna"},
        )
        login = await client.post(
            "/api/v1/auth/login", json={"email": "anna@test.it", "password": "password123"}
        )
        third = {"Authorization": f"Bearer {login.json()['access_token']}"}

        response = await client.post(f"{TRIPS}/join", json={"code": code}, headers=third)
        assert response.status_code == 400


class TestMembers:
    async def test_lists_every_member(
        self,
        client: AsyncClient,
        trip: dict,
        invite_code: str,
        auth_headers: dict,
        other_headers: dict,
    ):
        await client.post(f"{TRIPS}/join", json={"code": invite_code}, headers=other_headers)
        response = await client.get(f"{TRIPS}/{trip['id']}/members", headers=auth_headers)
        assert response.status_code == 200
        assert {m["role"] for m in response.json()} == {"owner", "member"}

    async def test_member_list_never_leaks_hashes(
        self, client: AsyncClient, trip: dict, auth_headers: dict
    ):
        response = await client.get(f"{TRIPS}/{trip['id']}/members", headers=auth_headers)
        assert "password_hash" not in response.text

    async def test_member_can_leave(
        self, client: AsyncClient, trip: dict, invite_code: str, other_headers: dict
    ):
        await client.post(f"{TRIPS}/join", json={"code": invite_code}, headers=other_headers)
        left = await client.delete(f"{TRIPS}/{trip['id']}/members/me", headers=other_headers)
        assert left.status_code == 204

        gone = await client.get(f"{TRIPS}/{trip['id']}", headers=other_headers)
        assert gone.status_code == 404

    # Leaving as an owner, and every other membership rule, is covered in
    # test_members.py: an owner alone deletes the trip, an owner with company
    # has to hand it over first.


class TestDelete:
    async def test_owner_can_delete(self, client: AsyncClient, trip: dict, auth_headers: dict):
        deleted = await client.delete(f"{TRIPS}/{trip['id']}", headers=auth_headers)
        assert deleted.status_code == 204

        gone = await client.get(f"{TRIPS}/{trip['id']}", headers=auth_headers)
        assert gone.status_code == 404

    async def test_delete_cascades_to_memberships(
        self, client: AsyncClient, trip: dict, auth_headers: dict, db: AsyncSession
    ):
        await client.delete(f"{TRIPS}/{trip['id']}", headers=auth_headers)
        remaining = await db.scalar(select(TripMember).where(TripMember.trip_id == trip["id"]))
        assert remaining is None


class TestCurrencyValidation:
    """A trip's currency is a label, not a conversion, which is exactly why it
    has to be a real one: nothing later can repair a column of numbers with a
    meaningless symbol in front."""

    async def test_a_made_up_code_is_rejected(self, client: AsyncClient, auth_headers: dict):
        response = await client.post(
            TRIPS, json={"name": "Lisbona", "base_currency": "ABC"}, headers=auth_headers
        )
        assert response.status_code == 422

    async def test_the_no_currency_code_is_rejected(self, client: AsyncClient, auth_headers: dict):
        """XXX is three letters and passes a length check, which is what the
        length check was worth."""
        response = await client.post(
            TRIPS, json={"name": "Lisbona", "base_currency": "XXX"}, headers=auth_headers
        )
        assert response.status_code == 422

    async def test_lower_case_is_accepted_and_stored_upper(
        self, client: AsyncClient, auth_headers: dict
    ):
        """A sloppy client is not a wrong user, and storing both "eur" and
        "EUR" would split one currency in two."""
        response = await client.post(
            TRIPS, json={"name": "Tokyo", "base_currency": "jpy"}, headers=auth_headers
        )
        assert response.status_code == 201
        assert response.json()["base_currency"] == "JPY"

    async def test_editing_to_a_bad_code_is_rejected(
        self, client: AsyncClient, trip: dict, auth_headers: dict
    ):
        response = await client.patch(
            f"{TRIPS}/{trip['id']}", json={"base_currency": "ZZZ"}, headers=auth_headers
        )
        assert response.status_code == 422

    async def test_leaving_the_currency_alone_still_works(
        self, client: AsyncClient, trip: dict, auth_headers: dict
    ):
        """The validator must not turn an absent field into a rejected one."""
        response = await client.patch(
            f"{TRIPS}/{trip['id']}", json={"name": "Lisbona 2027"}, headers=auth_headers
        )
        assert response.status_code == 200
        assert response.json()["base_currency"] == "EUR"
