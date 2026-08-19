"""Membership rules: removal, ownership transfer, leaving, and the money that
blocks all three.

The invariant every test here defends: a trip has exactly one owner, and nobody
walks away from it with an open balance.
"""

from uuid import UUID, uuid4

import pytest
from httpx import AsyncClient
from sqlalchemy import select
from sqlalchemy.exc import IntegrityError
from sqlalchemy.ext.asyncio import AsyncSession

from app.models import MemberRole, TripMember

TRIPS = "/api/v1/trips"
AUTH = "/api/v1/auth"
THIRD_USER = {"email": "giulia@test.it", "password": "password123", "display_name": "Giulia"}


async def _me(client: AsyncClient, headers: dict) -> str:
    response = await client.get("/api/v1/auth/me", headers=headers)
    return response.json()["id"]


async def _headers_for(client: AsyncClient, user: dict) -> dict[str, str]:
    await client.post("/api/v1/auth/register", json=user)
    response = await client.post(
        "/api/v1/auth/login", json={"email": user["email"], "password": user["password"]}
    )
    return {"Authorization": f"Bearer {response.json()['access_token']}"}


async def _join(client: AsyncClient, code: str, headers: dict) -> None:
    await client.post(f"{TRIPS}/join", json={"code": code}, headers=headers)


async def _members(client: AsyncClient, trip_id: str, headers: dict) -> list[dict]:
    response = await client.get(f"{TRIPS}/{trip_id}/members", headers=headers)
    return response.json()


async def _current(client: AsyncClient, trip_id: str, headers: dict) -> list[dict]:
    """Only who is still in the trip: the list also carries former members."""
    return [m for m in await _members(client, trip_id, headers) if m["left_at"] is None]


async def _roles(client: AsyncClient, trip_id: str, headers: dict) -> dict[str, str]:
    return {m["user"]["id"]: m["role"] for m in await _current(client, trip_id, headers)}


async def _share_expense(
    client: AsyncClient,
    trip_id: str,
    headers: dict,
    *,
    paid_by: str,
    participants: list[str],
    amount_cents: int = 2000,
) -> None:
    await client.post(
        f"{TRIPS}/{trip_id}/expenses",
        json={
            "description": "Cena",
            "amount_cents": amount_cents,
            "paid_by": paid_by,
            "participants": participants,
        },
        headers=headers,
    )


class TestRemoveMember:
    async def test_owner_removes_a_member(
        self,
        client: AsyncClient,
        trip: dict,
        invite_code: str,
        auth_headers: dict,
        other_headers: dict,
    ):
        await _join(client, invite_code, other_headers)
        member_id = await _me(client, other_headers)

        response = await client.delete(
            f"{TRIPS}/{trip['id']}/members/{member_id}", headers=auth_headers
        )
        assert response.status_code == 204

        remaining = await _current(client, trip["id"], auth_headers)
        assert [m["user"]["id"] for m in remaining] == [await _me(client, auth_headers)]

    async def test_access_stops_immediately(
        self,
        client: AsyncClient,
        trip: dict,
        invite_code: str,
        auth_headers: dict,
        other_headers: dict,
    ):
        await _join(client, invite_code, other_headers)
        member_id = await _me(client, other_headers)
        await client.delete(f"{TRIPS}/{trip['id']}/members/{member_id}", headers=auth_headers)

        response = await client.get(f"{TRIPS}/{trip['id']}", headers=other_headers)
        assert response.status_code == 404

    async def test_a_member_cannot_remove_anyone(
        self,
        client: AsyncClient,
        trip: dict,
        invite_code: str,
        auth_headers: dict,
        other_headers: dict,
    ):
        await _join(client, invite_code, other_headers)
        owner_id = await _me(client, auth_headers)

        response = await client.delete(
            f"{TRIPS}/{trip['id']}/members/{owner_id}", headers=other_headers
        )
        assert response.status_code == 403

    async def test_unknown_user_is_404(self, client: AsyncClient, trip: dict, auth_headers: dict):
        response = await client.delete(
            f"{TRIPS}/{trip['id']}/members/{uuid4()}", headers=auth_headers
        )
        assert response.status_code == 404

    async def test_a_user_who_never_joined_is_404(
        self, client: AsyncClient, trip: dict, auth_headers: dict, other_headers: dict
    ):
        """Existing account, no membership here: nothing to remove."""
        outsider_id = await _me(client, other_headers)
        response = await client.delete(
            f"{TRIPS}/{trip['id']}/members/{outsider_id}", headers=auth_headers
        )
        assert response.status_code == 404

    async def test_owner_cannot_remove_themselves(
        self, client: AsyncClient, trip: dict, auth_headers: dict
    ):
        owner_id = await _me(client, auth_headers)
        response = await client.delete(
            f"{TRIPS}/{trip['id']}/members/{owner_id}", headers=auth_headers
        )
        assert response.status_code == 409
        assert response.json()["detail"]["code"] == "owner_must_transfer"

    async def test_a_debt_blocks_removal(
        self,
        client: AsyncClient,
        trip: dict,
        invite_code: str,
        auth_headers: dict,
        other_headers: dict,
    ):
        """Their expenses cannot be deleted, so they cannot be dropped either."""
        await _join(client, invite_code, other_headers)
        owner_id = await _me(client, auth_headers)
        member_id = await _me(client, other_headers)
        await _share_expense(
            client,
            trip["id"],
            auth_headers,
            paid_by=owner_id,
            participants=[owner_id, member_id],
        )

        response = await client.delete(
            f"{TRIPS}/{trip['id']}/members/{member_id}", headers=auth_headers
        )
        assert response.status_code == 409

        detail = response.json()["detail"]
        assert detail["code"] == "outstanding_balance"
        assert detail["user_id"] == member_id
        # Negative: they owe. The client turns this into "Luca owes €10.00".
        assert detail["balance_cents"] == -1000

    async def test_removal_clears_assignments_but_keeps_the_task(
        self,
        client: AsyncClient,
        trip: dict,
        invite_code: str,
        auth_headers: dict,
        other_headers: dict,
    ):
        await _join(client, invite_code, other_headers)
        owner_id = await _me(client, auth_headers)
        member_id = await _me(client, other_headers)
        await client.post(
            f"{TRIPS}/{trip['id']}/items",
            json={
                "type": "task",
                "title": "Comprare il ghiaccio",
                "assigned_to": [owner_id, member_id],
            },
            headers=auth_headers,
        )

        await client.delete(f"{TRIPS}/{trip['id']}/members/{member_id}", headers=auth_headers)

        items = await client.get(f"{TRIPS}/{trip['id']}/items", headers=auth_headers)
        assert [i["title"] for i in items.json()] == ["Comprare il ghiaccio"]
        assert items.json()[0]["assignees"] == [owner_id]

    async def test_settled_history_survives_a_removal(
        self,
        client: AsyncClient,
        trip: dict,
        invite_code: str,
        auth_headers: dict,
        other_headers: dict,
    ):
        await _join(client, invite_code, other_headers)
        owner_id = await _me(client, auth_headers)
        member_id = await _me(client, other_headers)
        await _share_expense(
            client,
            trip["id"],
            auth_headers,
            paid_by=owner_id,
            participants=[owner_id, member_id],
        )
        # The member repays their half, so the balance is zero on both sides.
        await client.post(
            f"{TRIPS}/{trip['id']}/settlements",
            json={"to_user_id": owner_id, "amount_cents": 1000},
            headers=other_headers,
        )

        removed = await client.delete(
            f"{TRIPS}/{trip['id']}/members/{member_id}", headers=auth_headers
        )
        assert removed.status_code == 204

        expenses = await client.get(f"{TRIPS}/{trip['id']}/expenses", headers=auth_headers)
        assert len(expenses.json()["items"]) == 1
        assert len(expenses.json()["items"][0]["shares"]) == 2


class TestPastMembers:
    """Former members stay listed, with no access, so the ledger can name them."""

    async def test_a_removed_member_is_remembered(
        self,
        client: AsyncClient,
        trip: dict,
        invite_code: str,
        auth_headers: dict,
        other_headers: dict,
    ):
        await _join(client, invite_code, other_headers)
        member_id = await _me(client, other_headers)
        await client.delete(f"{TRIPS}/{trip['id']}/members/{member_id}", headers=auth_headers)

        listed = await _members(client, trip["id"], auth_headers)
        past = [m for m in listed if m["left_at"] is not None]
        assert [m["user"]["id"] for m in past] == [member_id]
        assert past[0]["user"]["display_name"] == "Luca"

    async def test_current_members_have_no_left_at(
        self, client: AsyncClient, trip: dict, auth_headers: dict
    ):
        listed = await _members(client, trip["id"], auth_headers)
        assert [m["left_at"] for m in listed] == [None]

    async def test_being_remembered_grants_nothing(
        self,
        client: AsyncClient,
        trip: dict,
        invite_code: str,
        auth_headers: dict,
        other_headers: dict,
    ):
        """The history table is descriptive; authorization still reads memberships."""
        await _join(client, invite_code, other_headers)
        await client.delete(f"{TRIPS}/{trip['id']}/members/me", headers=other_headers)

        assert (await client.get(f"{TRIPS}/{trip['id']}", headers=other_headers)).status_code == 404
        items = await client.get(f"{TRIPS}/{trip['id']}/items", headers=other_headers)
        assert items.status_code == 404

    async def test_the_name_behind_an_old_share_is_still_resolvable(
        self,
        client: AsyncClient,
        trip: dict,
        invite_code: str,
        auth_headers: dict,
        other_headers: dict,
    ):
        """The reason this table exists: shares outlive the membership."""
        await _join(client, invite_code, other_headers)
        owner_id = await _me(client, auth_headers)
        member_id = await _me(client, other_headers)
        await _share_expense(
            client,
            trip["id"],
            auth_headers,
            paid_by=owner_id,
            participants=[owner_id, member_id],
        )
        await client.post(
            f"{TRIPS}/{trip['id']}/settlements",
            json={"to_user_id": owner_id, "amount_cents": 1000},
            headers=other_headers,
        )
        await client.delete(f"{TRIPS}/{trip['id']}/members/{member_id}", headers=auth_headers)

        expenses = await client.get(f"{TRIPS}/{trip['id']}/expenses", headers=auth_headers)
        share_ids = {s["user_id"] for s in expenses.json()["items"][0]["shares"]}
        listed = {m["user"]["id"] for m in await _members(client, trip["id"], auth_headers)}
        assert share_ids <= listed

    async def test_the_role_they_held_is_kept(
        self,
        client: AsyncClient,
        trip: dict,
        invite_code: str,
        auth_headers: dict,
        other_headers: dict,
    ):
        """A former owner left as a member, because handing over comes first."""
        await _join(client, invite_code, other_headers)
        owner_id = await _me(client, auth_headers)
        member_id = await _me(client, other_headers)
        await client.post(f"{TRIPS}/{trip['id']}/members/{member_id}/owner", headers=auth_headers)
        await client.delete(f"{TRIPS}/{trip['id']}/members/me", headers=auth_headers)

        listed = await _members(client, trip["id"], other_headers)
        past = [m for m in listed if m["left_at"] is not None]
        assert past[0]["user"]["id"] == owner_id
        assert past[0]["role"] == "member"

    async def test_coming_back_makes_them_current_again(
        self,
        client: AsyncClient,
        trip: dict,
        invite_code: str,
        auth_headers: dict,
        other_headers: dict,
    ):
        """And only once: nobody is both a member and a former member."""
        await _join(client, invite_code, other_headers)
        member_id = await _me(client, other_headers)
        await client.delete(f"{TRIPS}/{trip['id']}/members/{member_id}", headers=auth_headers)
        await _join(client, invite_code, other_headers)

        listed = await _members(client, trip["id"], auth_headers)
        theirs = [m for m in listed if m["user"]["id"] == member_id]
        assert len(theirs) == 1
        assert theirs[0]["left_at"] is None

    async def test_leaving_twice_is_recorded_once(
        self,
        client: AsyncClient,
        trip: dict,
        invite_code: str,
        auth_headers: dict,
        other_headers: dict,
    ):
        await _join(client, invite_code, other_headers)
        await client.delete(f"{TRIPS}/{trip['id']}/members/me", headers=other_headers)
        await _join(client, invite_code, other_headers)
        await client.delete(f"{TRIPS}/{trip['id']}/members/me", headers=other_headers)

        listed = await _members(client, trip["id"], auth_headers)
        assert len([m for m in listed if m["left_at"] is not None]) == 1


class TestTransferOwnership:
    async def test_transfer_swaps_the_two_roles(
        self,
        client: AsyncClient,
        trip: dict,
        invite_code: str,
        auth_headers: dict,
        other_headers: dict,
    ):
        await _join(client, invite_code, other_headers)
        owner_id = await _me(client, auth_headers)
        member_id = await _me(client, other_headers)

        response = await client.post(
            f"{TRIPS}/{trip['id']}/members/{member_id}/owner", headers=auth_headers
        )
        assert response.status_code == 200

        roles = {m["user"]["id"]: m["role"] for m in response.json()}
        assert roles == {member_id: "owner", owner_id: "member"}
        assert list(roles.values()).count("owner") == 1

    async def test_a_member_cannot_transfer(
        self,
        client: AsyncClient,
        trip: dict,
        invite_code: str,
        auth_headers: dict,
        other_headers: dict,
    ):
        await _join(client, invite_code, other_headers)
        member_id = await _me(client, other_headers)

        response = await client.post(
            f"{TRIPS}/{trip['id']}/members/{member_id}/owner", headers=other_headers
        )
        assert response.status_code == 403

    async def test_target_must_be_a_member(
        self, client: AsyncClient, trip: dict, auth_headers: dict, other_headers: dict
    ):
        outsider_id = await _me(client, other_headers)
        response = await client.post(
            f"{TRIPS}/{trip['id']}/members/{outsider_id}/owner", headers=auth_headers
        )
        assert response.status_code == 404

    async def test_transferring_to_yourself_is_a_no_op(
        self, client: AsyncClient, trip: dict, auth_headers: dict
    ):
        owner_id = await _me(client, auth_headers)
        response = await client.post(
            f"{TRIPS}/{trip['id']}/members/{owner_id}/owner", headers=auth_headers
        )
        assert response.status_code == 200
        assert [m["role"] for m in response.json()] == ["owner"]

    async def test_the_new_owner_holds_the_powers(
        self,
        client: AsyncClient,
        trip: dict,
        invite_code: str,
        auth_headers: dict,
        other_headers: dict,
    ):
        await _join(client, invite_code, other_headers)
        third = await _headers_for(client, THIRD_USER)
        await _join(client, invite_code, third)

        owner_id = await _me(client, auth_headers)
        member_id = await _me(client, other_headers)
        third_id = await _me(client, third)
        await client.post(f"{TRIPS}/{trip['id']}/members/{member_id}/owner", headers=auth_headers)

        # The new owner can remove people…
        removed = await client.delete(
            f"{TRIPS}/{trip['id']}/members/{third_id}", headers=other_headers
        )
        assert removed.status_code == 204
        # …and the previous one cannot any more.
        refused = await client.delete(
            f"{TRIPS}/{trip['id']}/members/{member_id}", headers=auth_headers
        )
        assert refused.status_code == 403
        assert (await _roles(client, trip["id"], auth_headers))[owner_id] == "member"

    async def test_the_old_owner_can_then_leave(
        self,
        client: AsyncClient,
        trip: dict,
        invite_code: str,
        auth_headers: dict,
        other_headers: dict,
    ):
        await _join(client, invite_code, other_headers)
        member_id = await _me(client, other_headers)
        await client.post(f"{TRIPS}/{trip['id']}/members/{member_id}/owner", headers=auth_headers)

        response = await client.delete(f"{TRIPS}/{trip['id']}/members/me", headers=auth_headers)
        assert response.status_code == 204
        assert len(await _current(client, trip["id"], other_headers)) == 1


class TestLeave:
    async def test_a_settled_member_leaves(
        self,
        client: AsyncClient,
        trip: dict,
        invite_code: str,
        auth_headers: dict,
        other_headers: dict,
    ):
        await _join(client, invite_code, other_headers)

        response = await client.delete(f"{TRIPS}/{trip['id']}/members/me", headers=other_headers)
        assert response.status_code == 204
        assert len(await _current(client, trip["id"], auth_headers)) == 1

    async def test_a_debtor_cannot_leave(
        self,
        client: AsyncClient,
        trip: dict,
        invite_code: str,
        auth_headers: dict,
        other_headers: dict,
    ):
        await _join(client, invite_code, other_headers)
        owner_id = await _me(client, auth_headers)
        member_id = await _me(client, other_headers)
        await _share_expense(
            client,
            trip["id"],
            auth_headers,
            paid_by=owner_id,
            participants=[owner_id, member_id],
        )

        response = await client.delete(f"{TRIPS}/{trip['id']}/members/me", headers=other_headers)
        assert response.status_code == 409
        assert response.json()["detail"]["code"] == "outstanding_balance"
        assert response.json()["detail"]["balance_cents"] == -1000

    async def test_a_creditor_cannot_leave_either(
        self,
        client: AsyncClient,
        trip: dict,
        invite_code: str,
        auth_headers: dict,
        other_headers: dict,
    ):
        """Being owed money is just as unresolvable once you are gone."""
        await _join(client, invite_code, other_headers)
        owner_id = await _me(client, auth_headers)
        member_id = await _me(client, other_headers)
        await _share_expense(
            client,
            trip["id"],
            other_headers,
            paid_by=member_id,
            participants=[owner_id, member_id],
        )

        response = await client.delete(f"{TRIPS}/{trip['id']}/members/me", headers=other_headers)
        assert response.status_code == 409
        assert response.json()["detail"]["balance_cents"] == 1000

    async def test_leaving_is_allowed_once_settled(
        self,
        client: AsyncClient,
        trip: dict,
        invite_code: str,
        auth_headers: dict,
        other_headers: dict,
    ):
        await _join(client, invite_code, other_headers)
        owner_id = await _me(client, auth_headers)
        member_id = await _me(client, other_headers)
        await _share_expense(
            client,
            trip["id"],
            auth_headers,
            paid_by=owner_id,
            participants=[owner_id, member_id],
        )
        await client.post(
            f"{TRIPS}/{trip['id']}/settlements",
            json={"to_user_id": owner_id, "amount_cents": 1000},
            headers=other_headers,
        )

        response = await client.delete(f"{TRIPS}/{trip['id']}/members/me", headers=other_headers)
        assert response.status_code == 204

        expenses = await client.get(f"{TRIPS}/{trip['id']}/expenses", headers=auth_headers)
        assert len(expenses.json()["items"]) == 1

    async def test_an_owner_with_company_must_transfer_first(
        self,
        client: AsyncClient,
        trip: dict,
        invite_code: str,
        auth_headers: dict,
        other_headers: dict,
    ):
        await _join(client, invite_code, other_headers)

        response = await client.delete(f"{TRIPS}/{trip['id']}/members/me", headers=auth_headers)
        assert response.status_code == 409
        assert response.json()["detail"]["code"] == "owner_must_transfer"

    async def test_the_last_member_leaving_deletes_the_trip(
        self, client: AsyncClient, trip: dict, auth_headers: dict
    ):
        response = await client.delete(f"{TRIPS}/{trip['id']}/members/me", headers=auth_headers)
        assert response.status_code == 204

        gone = await client.get(f"{TRIPS}/{trip['id']}", headers=auth_headers)
        assert gone.status_code == 404
        assert (await client.get(TRIPS, headers=auth_headers)).json() == []

    async def test_the_last_member_leaves_even_with_expenses(
        self, client: AsyncClient, trip: dict, auth_headers: dict
    ):
        """Alone, there is nobody to owe: their own spending nets to zero."""
        owner_id = await _me(client, auth_headers)
        await _share_expense(
            client, trip["id"], auth_headers, paid_by=owner_id, participants=[owner_id]
        )

        response = await client.delete(f"{TRIPS}/{trip['id']}/members/me", headers=auth_headers)
        assert response.status_code == 204
        assert (await client.get(f"{TRIPS}/{trip['id']}", headers=auth_headers)).status_code == 404

    async def test_leaving_clears_assignments(
        self,
        client: AsyncClient,
        trip: dict,
        invite_code: str,
        auth_headers: dict,
        other_headers: dict,
    ):
        await _join(client, invite_code, other_headers)
        member_id = await _me(client, other_headers)
        await client.post(
            f"{TRIPS}/{trip['id']}/items",
            json={"type": "task", "title": "Portare il caricatore", "assigned_to": [member_id]},
            headers=auth_headers,
        )

        await client.delete(f"{TRIPS}/{trip['id']}/members/me", headers=other_headers)

        items = await client.get(f"{TRIPS}/{trip['id']}/items", headers=auth_headers)
        assert items.json()[0]["assignees"] == []


class TestOnlyOneOwner:
    """A trip has exactly one owner, and two transfers at once used to end it
    with two.

    The old code read the role, then wrote both rows. Inside one transaction
    that looks atomic and is not: two callers each saw a trip with one owner,
    each demoted the same person, and each promoted somebody different. Nobody
    could undo it afterwards — neither of the two owners was wrong.
    """

    async def test_the_second_transfer_is_refused(
        self,
        client: AsyncClient,
        trip: dict,
        invite_code: str,
        auth_headers: dict,
        other_headers: dict,
        db: AsyncSession,
    ):
        """Stands in for the race: the second call arrives with a caller who is
        no longer the owner, which is exactly what the losing transaction sees."""
        await client.post(f"{TRIPS}/join", json={"code": invite_code}, headers=other_headers)
        theirs = (await client.get(f"{AUTH}/me", headers=other_headers)).json()["id"]

        first = await client.post(
            f"{TRIPS}/{trip['id']}/members/{theirs}/owner", headers=auth_headers
        )
        assert first.status_code == 200

        second = await client.post(
            f"{TRIPS}/{trip['id']}/members/{theirs}/owner", headers=auth_headers
        )
        # 403: the caller stopped being the owner, so the dependency turns them
        # away before the service is ever reached.
        assert second.status_code == 403

    async def test_the_database_refuses_a_second_owner(
        self,
        client: AsyncClient,
        trip: dict,
        invite_code: str,
        other_headers: dict,
        db: AsyncSession,
    ):
        """The backstop, tested directly.

        Every path that promotes somebody should go through the service, but the
        index is what makes "two owners" impossible for the ones that do not —
        a migration, a script, an endpoint written later.
        """
        await client.post(f"{TRIPS}/join", json={"code": invite_code}, headers=other_headers)
        membership = await db.scalar(
            select(TripMember).where(
                TripMember.trip_id == UUID(trip["id"]),
                TripMember.role == MemberRole.MEMBER,
            )
        )

        membership.role = MemberRole.OWNER
        with pytest.raises(IntegrityError):
            await db.commit()
        await db.rollback()

    async def test_a_normal_transfer_still_works(
        self,
        client: AsyncClient,
        trip: dict,
        invite_code: str,
        auth_headers: dict,
        other_headers: dict,
        db: AsyncSession,
    ):
        """The index checks itself per statement, so demoting has to reach the
        database before promoting or the outgoing owner trips it."""
        await client.post(f"{TRIPS}/join", json={"code": invite_code}, headers=other_headers)
        theirs = (await client.get(f"{AUTH}/me", headers=other_headers)).json()["id"]

        response = await client.post(
            f"{TRIPS}/{trip['id']}/members/{theirs}/owner", headers=auth_headers
        )
        assert response.status_code == 200

        owners = [m for m in response.json() if m["role"] == "owner"]
        assert [m["user"]["id"] for m in owners] == [theirs]
