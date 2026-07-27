"""Editing a profile, changing a password, closing an account.

The three of them share one property worth testing hard: they all change who can
get in. A password change that leaves an intruder's session alive achieves
nothing, and an account that disappears out from under a trip leaves a group
nobody can administer.
"""

from httpx import AsyncClient
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models import Expense, RefreshToken, Trip, TripMember, User
from tests.conftest import SECOND_USER, USER

AUTH = "/api/v1/auth"
TRIPS = "/api/v1/trips"


async def _login(client: AsyncClient, user: dict) -> dict:
    response = await client.post(
        f"{AUTH}/login", json={"email": user["email"], "password": user["password"]}
    )
    return response.json()


class TestUpdateProfile:
    async def test_the_name_can_be_changed(self, client: AsyncClient, auth_headers: dict):
        response = await client.patch(
            f"{AUTH}/me", json={"display_name": "Mario Rossi"}, headers=auth_headers
        )
        assert response.status_code == 200
        assert response.json()["display_name"] == "Mario Rossi"

        assert (await client.get(f"{AUTH}/me", headers=auth_headers)).json()[
            "display_name"
        ] == "Mario Rossi"

    async def test_surrounding_space_is_dropped(self, client: AsyncClient, auth_headers: dict):
        response = await client.patch(
            f"{AUTH}/me", json={"display_name": "  Mario  "}, headers=auth_headers
        )
        assert response.json()["display_name"] == "Mario"

    async def test_an_empty_name_is_refused(self, client: AsyncClient, auth_headers: dict):
        """A blank name would leave the person nameless everywhere they appear."""
        response = await client.patch(
            f"{AUTH}/me", json={"display_name": "   "}, headers=auth_headers
        )
        assert response.status_code == 422

    async def test_the_email_cannot_be_changed_here(self, client: AsyncClient, auth_headers: dict):
        """Unknown keys are ignored rather than applied: pointing an account at
        another inbox has to prove that inbox first."""
        await client.patch(f"{AUTH}/me", json={"email": "altro@test.it"}, headers=auth_headers)
        assert (await client.get(f"{AUTH}/me", headers=auth_headers)).json()["email"] == USER[
            "email"
        ]

    async def test_a_stranger_cannot(self, client: AsyncClient):
        assert (await client.patch(f"{AUTH}/me", json={"display_name": "X"})).status_code == 401


class TestChangePassword:
    async def test_the_new_password_works_and_the_old_one_stops(
        self, client: AsyncClient, auth_headers: dict
    ):
        response = await client.post(
            f"{AUTH}/change-password",
            json={"current_password": USER["password"], "new_password": "nuovapassword1"},
            headers=auth_headers,
        )
        assert response.status_code == 200

        assert (
            await client.post(
                f"{AUTH}/login", json={"email": USER["email"], "password": USER["password"]}
            )
        ).status_code == 401
        assert (
            await client.post(
                f"{AUTH}/login", json={"email": USER["email"], "password": "nuovapassword1"}
            )
        ).status_code == 200

    async def test_the_wrong_current_password_is_refused(
        self, client: AsyncClient, auth_headers: dict
    ):
        """Holding an access token is not enough: a borrowed phone must not be
        able to lock the owner out."""
        response = await client.post(
            f"{AUTH}/change-password",
            json={"current_password": "sbagliata", "new_password": "nuovapassword1"},
            headers=auth_headers,
        )
        assert response.status_code == 401
        assert (
            await client.post(
                f"{AUTH}/login", json={"email": USER["email"], "password": USER["password"]}
            )
        ).status_code == 200

    async def test_a_short_password_is_refused(self, client: AsyncClient, auth_headers: dict):
        response = await client.post(
            f"{AUTH}/change-password",
            json={"current_password": USER["password"], "new_password": "corta"},
            headers=auth_headers,
        )
        assert response.status_code == 422

    async def test_every_other_session_falls(
        self, client: AsyncClient, tokens: dict, auth_headers: dict
    ):
        """The reason the endpoint exists.

        Someone changing their password because they think another person is in
        their account gains nothing if that person's session keeps working.
        """
        elsewhere = await _login(client, USER)

        changed = await client.post(
            f"{AUTH}/change-password",
            json={"current_password": USER["password"], "new_password": "nuovapassword1"},
            headers=auth_headers,
        )

        # The other device can no longer trade its refresh token for anything.
        assert (
            await client.post(f"{AUTH}/refresh", json={"refresh_token": elsewhere["refresh_token"]})
        ).status_code == 401
        # Nor can the token this caller arrived with: it is replaced, not spared.
        assert (
            await client.post(f"{AUTH}/refresh", json={"refresh_token": tokens["refresh_token"]})
        ).status_code == 401
        # The one handed back in exchange does work, so this device stays in.
        assert (
            await client.post(
                f"{AUTH}/refresh", json={"refresh_token": changed.json()["refresh_token"]}
            )
        ).status_code == 200


class TestDeleteAccount:
    async def test_a_lone_account_goes(
        self, client: AsyncClient, auth_headers: dict, db: AsyncSession
    ):
        assert (await client.delete(f"{AUTH}/me", headers=auth_headers)).status_code == 204

        # Not logged in again, under the old address or the old password.
        assert (
            await client.post(
                f"{AUTH}/login", json={"email": USER["email"], "password": USER["password"]}
            )
        ).status_code == 401

    async def test_the_identifying_fields_are_emptied(
        self, client: AsyncClient, auth_headers: dict, db: AsyncSession
    ):
        """The row survives because the ledger points at it, so what has to go is
        what identifies the person, not the record."""
        await client.delete(f"{AUTH}/me", headers=auth_headers)

        user = await db.scalar(select(User).where(User.display_name == ""))
        assert user is not None
        assert user.email.endswith("@deleted.invalid")
        assert user.is_active is False

    async def test_the_address_becomes_reusable(self, client: AsyncClient, auth_headers: dict):
        """Registering again with the same email has to work, or closing an
        account would burn it forever."""
        await client.delete(f"{AUTH}/me", headers=auth_headers)
        assert (await client.post(f"{AUTH}/register", json=USER)).status_code == 201

    async def test_every_session_falls(self, client: AsyncClient, tokens: dict, auth_headers: dict):
        await client.delete(f"{AUTH}/me", headers=auth_headers)
        assert (
            await client.post(f"{AUTH}/refresh", json={"refresh_token": tokens["refresh_token"]})
        ).status_code == 401

    async def test_a_trip_they_were_alone_in_goes_with_them(
        self, client: AsyncClient, trip: dict, auth_headers: dict, db: AsyncSession
    ):
        await client.delete(f"{AUTH}/me", headers=auth_headers)
        assert await db.get(Trip, trip["id"]) is None

    async def test_owning_a_trip_with_others_in_it_refuses(
        self,
        client: AsyncClient,
        trip: dict,
        invite_code: str,
        auth_headers: dict,
        other_headers: dict,
    ):
        """That group would be left with nobody who can invite, rename or close
        it, and picking a replacement is not the server's decision."""
        await client.post(f"{TRIPS}/join", json={"code": invite_code}, headers=other_headers)

        response = await client.delete(f"{AUTH}/me", headers=auth_headers)
        assert response.status_code == 409
        detail = response.json()["detail"]
        assert detail["code"] == "still_owns_trips"
        # The ids travel so the app can name the trips instead of saying "some".
        assert detail["trip_ids"] == [trip["id"]]

        # And nothing was half-done on the way to the refusal.
        assert (await client.get(f"{AUTH}/me", headers=auth_headers)).status_code == 200

    async def test_handing_the_trip_over_first_unblocks_it(
        self,
        client: AsyncClient,
        trip: dict,
        invite_code: str,
        auth_headers: dict,
        other_headers: dict,
    ):
        await client.post(f"{TRIPS}/join", json={"code": invite_code}, headers=other_headers)
        theirs = (await client.get(f"{AUTH}/me", headers=other_headers)).json()["id"]
        await client.post(f"{TRIPS}/{trip['id']}/members/{theirs}/owner", headers=auth_headers)

        assert (await client.delete(f"{AUTH}/me", headers=auth_headers)).status_code == 204
        # The trip is still there, and still has an owner.
        assert (await client.get(f"{TRIPS}/{trip['id']}", headers=other_headers)).status_code == 200

    async def test_being_a_plain_member_is_no_obstacle(
        self,
        client: AsyncClient,
        trip: dict,
        invite_code: str,
        auth_headers: dict,
        other_headers: dict,
        db: AsyncSession,
    ):
        await client.post(f"{TRIPS}/join", json={"code": invite_code}, headers=other_headers)
        theirs = (await client.get(f"{AUTH}/me", headers=other_headers)).json()["id"]

        assert (await client.delete(f"{AUTH}/me", headers=other_headers)).status_code == 204
        # They are out of the trip, which survives them.
        assert await db.scalar(select(TripMember).where(TripMember.user_id == theirs)) is None
        assert (await client.get(f"{TRIPS}/{trip['id']}", headers=auth_headers)).status_code == 200

    async def test_what_they_spent_is_not_rewritten(
        self,
        client: AsyncClient,
        trip: dict,
        invite_code: str,
        auth_headers: dict,
        other_headers: dict,
        db: AsyncSession,
    ):
        """The strongest reason the row is emptied instead of deleted: an expense
        they took part in decides what everybody else owes."""
        await client.post(f"{TRIPS}/join", json={"code": invite_code}, headers=other_headers)
        mine = (await client.get(f"{AUTH}/me", headers=auth_headers)).json()["id"]
        theirs = (await client.get(f"{AUTH}/me", headers=other_headers)).json()["id"]
        await client.post(
            f"{TRIPS}/{trip['id']}/expenses",
            json={
                "description": "Cena",
                "amount_cents": 6000,
                "paid_by": theirs,
                "participants": [mine, theirs],
            },
            headers=other_headers,
        )

        assert (await client.delete(f"{AUTH}/me", headers=other_headers)).status_code == 204

        expense = await db.scalar(select(Expense))
        assert expense is not None and expense.amount_cents == 6000
        report = await client.get(f"{TRIPS}/{trip['id']}/balance", headers=auth_headers)
        mine_balance = next(
            b["balance_cents"] for b in report.json()["balances"] if b["user_id"] == mine
        )
        assert mine_balance == -3000

    async def test_a_stranger_cannot(self, client: AsyncClient):
        assert (await client.delete(f"{AUTH}/me")).status_code == 401


class TestTokensAfterDeletion:
    async def test_no_new_session_can_be_opened(
        self, client: AsyncClient, auth_headers: dict, db: AsyncSession
    ):
        await client.delete(f"{AUTH}/me", headers=auth_headers)
        assert (
            await db.scalar(select(RefreshToken).where(RefreshToken.revoked_at.is_(None)))
        ) is None

    async def test_the_second_user_is_untouched(
        self, client: AsyncClient, auth_headers: dict, other_headers: dict
    ):
        await client.delete(f"{AUTH}/me", headers=auth_headers)
        response = await client.get(f"{AUTH}/me", headers=other_headers)
        assert response.status_code == 200
        assert response.json()["email"] == SECOND_USER["email"]
