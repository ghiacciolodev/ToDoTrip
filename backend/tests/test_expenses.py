"""Expense, balance and settlement tests through the API.

The unit tests in test_balance.py cover the arithmetic; these check that the
persistence layer feeds it correctly and that trip boundaries hold.
"""

from uuid import uuid4

import pytest
from httpx import AsyncClient

TRIPS = "/api/v1/trips"


@pytest.fixture
async def three_members(
    client: AsyncClient, trip: dict, invite_code: str, auth_headers: dict, other_headers: dict
) -> dict:
    """A trip with Mario (owner), Luca and Anna, plus everyone's ids and headers."""
    await client.post(f"{TRIPS}/join", json={"code": invite_code}, headers=other_headers)

    await client.post(
        "/api/v1/auth/register",
        json={
            "email": "anna@test.it",
            "password": "password123",
            "display_name": "Anna",
            "accepted_privacy": True,
        },
    )
    login = await client.post(
        "/api/v1/auth/login", json={"email": "anna@test.it", "password": "password123"}
    )
    anna_headers = {"Authorization": f"Bearer {login.json()['access_token']}"}
    await client.post(f"{TRIPS}/join", json={"code": invite_code}, headers=anna_headers)

    async def _id(headers: dict) -> str:
        response = await client.get("/api/v1/auth/me", headers=headers)
        return response.json()["id"]

    return {
        "trip_id": trip["id"],
        "mario": await _id(auth_headers),
        "luca": await _id(other_headers),
        "anna": await _id(anna_headers),
        "mario_headers": auth_headers,
        "luca_headers": other_headers,
        "anna_headers": anna_headers,
    }


class TestCreateExpense:
    async def test_even_split_creates_one_share_per_participant(
        self, client: AsyncClient, three_members: dict
    ):
        g = three_members
        response = await client.post(
            f"{TRIPS}/{g['trip_id']}/expenses",
            json={
                "description": "Cena",
                "amount_cents": 9000,
                "paid_by": g["mario"],
                "participants": [g["mario"], g["luca"], g["anna"]],
            },
            headers=g["mario_headers"],
        )
        assert response.status_code == 201
        assert {s["share_cents"] for s in response.json()["shares"]} == {3000}

    async def test_uneven_split_is_accepted(self, client: AsyncClient, three_members: dict):
        g = three_members
        response = await client.post(
            f"{TRIPS}/{g['trip_id']}/expenses",
            json={
                "description": "Hotel",
                "amount_cents": 10000,
                "paid_by": g["mario"],
                "shares": [
                    {"user_id": g["mario"], "share_cents": 6000},
                    {"user_id": g["luca"], "share_cents": 4000},
                ],
            },
            headers=g["mario_headers"],
        )
        assert response.status_code == 201

    async def test_shares_not_summing_to_total_are_rejected(
        self, client: AsyncClient, three_members: dict
    ):
        """The one invariant that must never break: shares reconstruct the total."""
        g = three_members
        response = await client.post(
            f"{TRIPS}/{g['trip_id']}/expenses",
            json={
                "description": "Sbagliata",
                "amount_cents": 10000,
                "paid_by": g["mario"],
                "shares": [{"user_id": g["mario"], "share_cents": 5000}],
            },
            headers=g["mario_headers"],
        )
        assert response.status_code == 422

    async def test_rounding_remainder_reaches_the_payer(
        self, client: AsyncClient, three_members: dict
    ):
        """10.00 across three is 3.34 + 3.33 + 3.33, and the payer takes the extra."""
        g = three_members
        response = await client.post(
            f"{TRIPS}/{g['trip_id']}/expenses",
            json={
                "description": "Caffè",
                "amount_cents": 1000,
                "paid_by": g["luca"],
                "participants": [g["mario"], g["luca"], g["anna"]],
            },
            headers=g["mario_headers"],
        )
        shares = {s["user_id"]: s["share_cents"] for s in response.json()["shares"]}
        assert shares[g["luca"]] == 334
        assert sum(shares.values()) == 1000

    async def test_zero_amount_is_rejected(self, client: AsyncClient, three_members: dict):
        g = three_members
        response = await client.post(
            f"{TRIPS}/{g['trip_id']}/expenses",
            json={
                "description": "X",
                "amount_cents": 0,
                "paid_by": g["mario"],
                "participants": [g["mario"]],
            },
            headers=g["mario_headers"],
        )
        assert response.status_code == 422

    async def test_outsider_cannot_be_a_participant(self, client: AsyncClient, three_members: dict):
        """A stranger in the split would corrupt every balance in the trip."""
        g = three_members
        response = await client.post(
            f"{TRIPS}/{g['trip_id']}/expenses",
            json={
                "description": "X",
                "amount_cents": 1000,
                "paid_by": g["mario"],
                "participants": [g["mario"], str(uuid4())],
            },
            headers=g["mario_headers"],
        )
        assert response.status_code == 422

    async def test_missing_split_is_rejected(self, client: AsyncClient, three_members: dict):
        g = three_members
        response = await client.post(
            f"{TRIPS}/{g['trip_id']}/expenses",
            json={"description": "X", "amount_cents": 1000, "paid_by": g["mario"]},
            headers=g["mario_headers"],
        )
        assert response.status_code == 422


class TestIsolation:
    async def test_outsider_cannot_read_expenses(
        self, client: AsyncClient, trip: dict, other_headers: dict
    ):
        response = await client.get(f"{TRIPS}/{trip['id']}/expenses", headers=other_headers)
        assert response.status_code == 404

    async def test_outsider_cannot_read_balances(
        self, client: AsyncClient, trip: dict, other_headers: dict
    ):
        response = await client.get(f"{TRIPS}/{trip['id']}/balance", headers=other_headers)
        assert response.status_code == 404


class TestBalance:
    async def test_single_expense_produces_symmetric_balances(
        self, client: AsyncClient, three_members: dict
    ):
        g = three_members
        await client.post(
            f"{TRIPS}/{g['trip_id']}/expenses",
            json={
                "description": "Cena",
                "amount_cents": 9000,
                "paid_by": g["mario"],
                "participants": [g["mario"], g["luca"], g["anna"]],
            },
            headers=g["mario_headers"],
        )
        response = await client.get(f"{TRIPS}/{g['trip_id']}/balance", headers=g["luca_headers"])
        balances = {b["user_id"]: b["balance_cents"] for b in response.json()["balances"]}
        assert balances[g["mario"]] == 6000
        assert balances[g["luca"]] == -3000
        assert balances[g["anna"]] == -3000

    async def test_balances_sum_to_zero(self, client: AsyncClient, three_members: dict):
        g = three_members
        for payer in ("mario", "luca", "anna"):
            await client.post(
                f"{TRIPS}/{g['trip_id']}/expenses",
                json={
                    "description": f"Spesa di {payer}",
                    "amount_cents": 4567,
                    "paid_by": g[payer],
                    "participants": [g["mario"], g["luca"], g["anna"]],
                },
                headers=g["mario_headers"],
            )
        response = await client.get(f"{TRIPS}/{g['trip_id']}/balance", headers=g["mario_headers"])
        assert sum(b["balance_cents"] for b in response.json()["balances"]) == 0

    async def test_members_with_no_activity_appear_at_zero(
        self, client: AsyncClient, three_members: dict
    ):
        g = three_members
        await client.post(
            f"{TRIPS}/{g['trip_id']}/expenses",
            json={
                "description": "Solo noi due",
                "amount_cents": 1000,
                "paid_by": g["mario"],
                "participants": [g["mario"], g["luca"]],
            },
            headers=g["mario_headers"],
        )
        response = await client.get(f"{TRIPS}/{g['trip_id']}/balance", headers=g["mario_headers"])
        balances = {b["user_id"]: b["balance_cents"] for b in response.json()["balances"]}
        assert balances[g["anna"]] == 0

    async def test_total_spent_ignores_settlements(self, client: AsyncClient, three_members: dict):
        """A repayment moves money between members; it is not a trip cost."""
        g = three_members
        await client.post(
            f"{TRIPS}/{g['trip_id']}/expenses",
            json={
                "description": "Cena",
                "amount_cents": 6000,
                "paid_by": g["mario"],
                "participants": [g["mario"], g["luca"]],
            },
            headers=g["mario_headers"],
        )
        await client.post(
            f"{TRIPS}/{g['trip_id']}/settlements",
            json={"to_user_id": g["mario"], "amount_cents": 3000},
            headers=g["luca_headers"],
        )
        response = await client.get(f"{TRIPS}/{g['trip_id']}/balance", headers=g["mario_headers"])
        assert response.json()["total_spent_cents"] == 6000

    async def test_deleting_an_expense_recomputes_balances(
        self, client: AsyncClient, three_members: dict
    ):
        """Balances are derived, so nothing needs invalidating."""
        g = three_members
        created = await client.post(
            f"{TRIPS}/{g['trip_id']}/expenses",
            json={
                "description": "Da cancellare",
                "amount_cents": 9000,
                "paid_by": g["mario"],
                "participants": [g["mario"], g["luca"], g["anna"]],
            },
            headers=g["mario_headers"],
        )
        await client.delete(
            f"{TRIPS}/{g['trip_id']}/expenses/{created.json()['id']}",
            headers=g["mario_headers"],
        )
        response = await client.get(f"{TRIPS}/{g['trip_id']}/balance", headers=g["mario_headers"])
        assert all(b["balance_cents"] == 0 for b in response.json()["balances"])

    async def test_deleting_one_expense_leaves_the_other_intact(
        self, client: AsyncClient, three_members: dict
    ):
        """Separates a cascade bug from an orphaned settlement.

        If this fails, deleting an expense is not taking its shares with it and
        the balances are wrong for a much more serious reason.
        """
        g = three_members
        first = await client.post(
            f"{TRIPS}/{g['trip_id']}/expenses",
            json={
                "description": "Prima",
                "amount_cents": 6000,
                "paid_by": g["mario"],
                "participants": [g["mario"], g["luca"]],
            },
            headers=g["mario_headers"],
        )
        await client.post(
            f"{TRIPS}/{g['trip_id']}/expenses",
            json={
                "description": "Seconda",
                "amount_cents": 2000,
                "paid_by": g["luca"],
                "participants": [g["mario"], g["luca"]],
            },
            headers=g["luca_headers"],
        )
        await client.delete(
            f"{TRIPS}/{g['trip_id']}/expenses/{first.json()['id']}",
            headers=g["mario_headers"],
        )

        response = await client.get(f"{TRIPS}/{g['trip_id']}/balance", headers=g["mario_headers"])
        body = response.json()
        balances = {b["user_id"]: b["balance_cents"] for b in body["balances"]}
        # Only the second expense remains: Luca paid 20, Mario owes his half.
        assert balances[g["luca"]] == 1000
        assert balances[g["mario"]] == -1000
        assert body["total_spent_cents"] == 2000


class TestSettlement:
    async def test_settling_up_clears_the_debt(self, client: AsyncClient, three_members: dict):
        """The full round trip: spend, owe, repay, back to zero."""
        g = three_members
        await client.post(
            f"{TRIPS}/{g['trip_id']}/expenses",
            json={
                "description": "Cena",
                "amount_cents": 6000,
                "paid_by": g["mario"],
                "participants": [g["mario"], g["luca"]],
            },
            headers=g["mario_headers"],
        )
        settled = await client.post(
            f"{TRIPS}/{g['trip_id']}/settlements",
            json={"to_user_id": g["mario"], "amount_cents": 3000, "note": "Bonifico"},
            headers=g["luca_headers"],
        )
        assert settled.status_code == 201

        response = await client.get(f"{TRIPS}/{g['trip_id']}/balance", headers=g["mario_headers"])
        balances = {b["user_id"]: b["balance_cents"] for b in response.json()["balances"]}
        assert balances[g["mario"]] == 0
        assert balances[g["luca"]] == 0
        assert response.json()["suggested_transfers"] == []

    async def test_sender_is_always_the_caller(self, client: AsyncClient, three_members: dict):
        """Nobody can declare someone else's debt repaid."""
        g = three_members
        response = await client.post(
            f"{TRIPS}/{g['trip_id']}/settlements",
            json={"to_user_id": g["mario"], "amount_cents": 1000},
            headers=g["luca_headers"],
        )
        assert response.json()["from_user_id"] == g["luca"]

    async def test_self_settlement_is_rejected(self, client: AsyncClient, three_members: dict):
        g = three_members
        response = await client.post(
            f"{TRIPS}/{g['trip_id']}/settlements",
            json={"to_user_id": g["luca"], "amount_cents": 1000},
            headers=g["luca_headers"],
        )
        assert response.status_code == 422

    async def test_settling_with_an_outsider_is_rejected(
        self, client: AsyncClient, three_members: dict
    ):
        g = three_members
        response = await client.post(
            f"{TRIPS}/{g['trip_id']}/settlements",
            json={"to_user_id": str(uuid4()), "amount_cents": 1000},
            headers=g["luca_headers"],
        )
        assert response.status_code == 422


class TestSettlementOutlivesItsExpense:
    """The behaviour behind "the balances went wrong after I deleted an expense".

    Deleting an expense takes its shares with it, but not the repayments made
    against it: the money really did change hands. The arithmetic is right and
    the result is surprising, so it is pinned down here and surfaced in the app,
    where repayments are now listed and can be undone.
    """

    async def test_the_repayment_survives_and_inverts_the_balance(
        self, client: AsyncClient, three_members: dict
    ):
        g = three_members
        expense = await client.post(
            f"{TRIPS}/{g['trip_id']}/expenses",
            json={
                "description": "Cena",
                "amount_cents": 6000,
                "paid_by": g["mario"],
                "participants": [g["mario"], g["luca"]],
            },
            headers=g["mario_headers"],
        )
        await client.post(
            f"{TRIPS}/{g['trip_id']}/settlements",
            json={"to_user_id": g["mario"], "amount_cents": 3000},
            headers=g["luca_headers"],
        )
        await client.delete(
            f"{TRIPS}/{g['trip_id']}/expenses/{expense.json()['id']}",
            headers=g["mario_headers"],
        )

        response = await client.get(f"{TRIPS}/{g['trip_id']}/balance", headers=g["mario_headers"])
        body = response.json()
        balances = {b["user_id"]: b["balance_cents"] for b in body["balances"]}
        # Luca paid 30 for something that no longer exists, so he is owed it.
        assert balances[g["luca"]] == 3000
        assert balances[g["mario"]] == -3000
        # And nothing was spent, which is what makes the figures look unexplained.
        assert body["total_spent_cents"] == 0

    async def test_undoing_the_repayment_clears_it(self, client: AsyncClient, three_members: dict):
        """The way out of the state above."""
        g = three_members
        expense = await client.post(
            f"{TRIPS}/{g['trip_id']}/expenses",
            json={
                "description": "Cena",
                "amount_cents": 6000,
                "paid_by": g["mario"],
                "participants": [g["mario"], g["luca"]],
            },
            headers=g["mario_headers"],
        )
        settlement = await client.post(
            f"{TRIPS}/{g['trip_id']}/settlements",
            json={"to_user_id": g["mario"], "amount_cents": 3000},
            headers=g["luca_headers"],
        )
        await client.delete(
            f"{TRIPS}/{g['trip_id']}/expenses/{expense.json()['id']}",
            headers=g["mario_headers"],
        )
        await client.delete(
            f"{TRIPS}/{g['trip_id']}/settlements/{settlement.json()['id']}",
            headers=g["luca_headers"],
        )

        response = await client.get(f"{TRIPS}/{g['trip_id']}/balance", headers=g["mario_headers"])
        assert all(b["balance_cents"] == 0 for b in response.json()["balances"])


class TestUndoSettlement:
    async def test_the_sender_can_undo(self, client: AsyncClient, three_members: dict):
        g = three_members
        await client.post(
            f"{TRIPS}/{g['trip_id']}/expenses",
            json={
                "description": "Cena",
                "amount_cents": 6000,
                "paid_by": g["mario"],
                "participants": [g["mario"], g["luca"]],
            },
            headers=g["mario_headers"],
        )
        settlement = await client.post(
            f"{TRIPS}/{g['trip_id']}/settlements",
            json={"to_user_id": g["mario"], "amount_cents": 3000},
            headers=g["luca_headers"],
        )

        undone = await client.delete(
            f"{TRIPS}/{g['trip_id']}/settlements/{settlement.json()['id']}",
            headers=g["luca_headers"],
        )
        assert undone.status_code == 204

        # Back to the debt that existed before the repayment.
        response = await client.get(f"{TRIPS}/{g['trip_id']}/balance", headers=g["mario_headers"])
        balances = {b["user_id"]: b["balance_cents"] for b in response.json()["balances"]}
        assert balances[g["luca"]] == -3000
        assert balances[g["mario"]] == 3000
        assert (
            await client.get(f"{TRIPS}/{g['trip_id']}/settlements", headers=g["luca_headers"])
        ).json() == []

    async def test_the_recipient_cannot_undo(self, client: AsyncClient, three_members: dict):
        """The same rule as recording one: nobody speaks for another's money."""
        g = three_members
        settlement = await client.post(
            f"{TRIPS}/{g['trip_id']}/settlements",
            json={"to_user_id": g["mario"], "amount_cents": 3000},
            headers=g["luca_headers"],
        )
        response = await client.delete(
            f"{TRIPS}/{g['trip_id']}/settlements/{settlement.json()['id']}",
            headers=g["mario_headers"],
        )
        assert response.status_code == 403

    async def test_an_unrelated_member_cannot_undo(self, client: AsyncClient, three_members: dict):
        g = three_members
        settlement = await client.post(
            f"{TRIPS}/{g['trip_id']}/settlements",
            json={"to_user_id": g["mario"], "amount_cents": 3000},
            headers=g["luca_headers"],
        )
        response = await client.delete(
            f"{TRIPS}/{g['trip_id']}/settlements/{settlement.json()['id']}",
            headers=g["anna_headers"],
        )
        assert response.status_code == 403

    async def test_unknown_settlement_is_404(self, client: AsyncClient, three_members: dict):
        g = three_members
        response = await client.delete(
            f"{TRIPS}/{g['trip_id']}/settlements/{uuid4()}", headers=g["mario_headers"]
        )
        assert response.status_code == 404

    async def test_a_settlement_id_does_not_cross_trips(
        self, client: AsyncClient, three_members: dict
    ):
        g = three_members
        settlement = await client.post(
            f"{TRIPS}/{g['trip_id']}/settlements",
            json={"to_user_id": g["mario"], "amount_cents": 3000},
            headers=g["luca_headers"],
        )
        other_trip = await client.post(TRIPS, json={"name": "Altro"}, headers=g["luca_headers"])
        response = await client.delete(
            f"{TRIPS}/{other_trip.json()['id']}/settlements/{settlement.json()['id']}",
            headers=g["luca_headers"],
        )
        assert response.status_code == 404


class TestSuggestedTransfers:
    async def test_transfers_settle_everyone(self, client: AsyncClient, three_members: dict):
        """Applying the suggestions must bring every balance to zero."""
        g = three_members
        await client.post(
            f"{TRIPS}/{g['trip_id']}/expenses",
            json={
                "description": "Hotel",
                "amount_cents": 12000,
                "paid_by": g["mario"],
                "participants": [g["mario"], g["luca"], g["anna"]],
            },
            headers=g["mario_headers"],
        )
        await client.post(
            f"{TRIPS}/{g['trip_id']}/expenses",
            json={
                "description": "Benzina",
                "amount_cents": 6000,
                "paid_by": g["luca"],
                "participants": [g["mario"], g["luca"], g["anna"]],
            },
            headers=g["luca_headers"],
        )
        report = await client.get(f"{TRIPS}/{g['trip_id']}/balance", headers=g["mario_headers"])
        body = report.json()

        residual = {b["user_id"]: b["balance_cents"] for b in body["balances"]}
        for t in body["suggested_transfers"]:
            residual[t["from_user_id"]] += t["amount_cents"]
            residual[t["to_user_id"]] -= t["amount_cents"]
        assert all(value == 0 for value in residual.values())

    async def test_no_transfers_when_nothing_was_spent(
        self, client: AsyncClient, three_members: dict
    ):
        g = three_members
        response = await client.get(f"{TRIPS}/{g['trip_id']}/balance", headers=g["mario_headers"])
        assert response.json()["suggested_transfers"] == []


class TestPagination:
    """The expenses list is the one that grows without a ceiling, so it is the
    one that is cut into pages."""

    async def _spend(self, client: AsyncClient, g: dict, count: int) -> None:
        for n in range(count):
            response = await client.post(
                f"{TRIPS}/{g['trip_id']}/expenses",
                json={
                    "description": f"Spesa {n}",
                    "amount_cents": 100 + n,
                    "paid_by": g["mario"],
                    "participants": [g["mario"], g["luca"]],
                },
                headers=g["mario_headers"],
            )
            assert response.status_code == 201

    async def test_first_page_is_capped_and_reports_the_total(
        self, client: AsyncClient, three_members: dict
    ):
        g = three_members
        await self._spend(client, g, 8)

        response = await client.get(
            f"{TRIPS}/{g['trip_id']}/expenses?limit=5", headers=g["mario_headers"]
        )
        body = response.json()

        assert response.status_code == 200
        assert len(body["items"]) == 5
        # The total counts the trip, not the page: a screen showing "8 expenses"
        # must not say 5 because that is all it has loaded.
        assert body["total"] == 8
        assert body["next_cursor"] is not None

    async def test_the_cursor_walks_the_whole_list_exactly_once(
        self, client: AsyncClient, three_members: dict
    ):
        g = three_members
        await self._spend(client, g, 8)

        seen: list[str] = []
        cursor: str | None = None
        for _ in range(10):  # a bound, so a broken cursor loops finitely
            url = f"{TRIPS}/{g['trip_id']}/expenses?limit=3"
            if cursor:
                url += f"&before={cursor}"
            body = (await client.get(url, headers=g["mario_headers"])).json()
            seen.extend(row["id"] for row in body["items"])
            cursor = body["next_cursor"]
            if cursor is None:
                break

        assert cursor is None
        assert len(seen) == 8
        # No row twice and none missing: the whole point of a keyset cursor.
        assert len(set(seen)) == 8

    async def test_the_last_page_has_no_cursor(self, client: AsyncClient, three_members: dict):
        g = three_members
        await self._spend(client, g, 3)

        body = (
            await client.get(f"{TRIPS}/{g['trip_id']}/expenses?limit=3", headers=g["mario_headers"])
        ).json()

        # Exactly limit rows and nothing after them: the extra-row lookahead has
        # to distinguish "full page, no more" from "full page, more to come".
        assert len(body["items"]) == 3
        assert body["next_cursor"] is None

    async def test_an_expense_added_mid_read_cannot_repeat_a_row(
        self, client: AsyncClient, three_members: dict
    ):
        """The reason for a keyset rather than an offset.

        With OFFSET, a row inserted at the top between two requests pushes
        everything down by one and page two opens with a row already read.
        """
        g = three_members
        await self._spend(client, g, 6)

        first = (
            await client.get(f"{TRIPS}/{g['trip_id']}/expenses?limit=3", headers=g["mario_headers"])
        ).json()
        await self._spend(client, g, 1)

        second = (
            await client.get(
                f"{TRIPS}/{g['trip_id']}/expenses?limit=3&before={first['next_cursor']}",
                headers=g["mario_headers"],
            )
        ).json()

        first_ids = {row["id"] for row in first["items"]}
        assert not first_ids & {row["id"] for row in second["items"]}

    async def test_a_mangled_cursor_gives_the_first_page(
        self, client: AsyncClient, three_members: dict
    ):
        g = three_members
        await self._spend(client, g, 2)

        response = await client.get(
            f"{TRIPS}/{g['trip_id']}/expenses?before=not-a-cursor", headers=g["mario_headers"]
        )

        # A query string somebody has edited by hand is not worth a 500.
        assert response.status_code == 200
        assert len(response.json()["items"]) == 2

    async def test_limit_above_the_maximum_is_refused(
        self, client: AsyncClient, three_members: dict
    ):
        g = three_members
        response = await client.get(
            f"{TRIPS}/{g['trip_id']}/expenses?limit=100000", headers=g["mario_headers"]
        )
        # Otherwise the page size is whatever the caller feels like, and
        # pagination protects nothing.
        assert response.status_code == 422

    async def test_balances_still_see_every_expense(self, client: AsyncClient, three_members: dict):
        """Paginating the list must not paginate the arithmetic."""
        g = three_members
        await self._spend(client, g, 40)  # more than one page

        report = (
            await client.get(f"{TRIPS}/{g['trip_id']}/balance", headers=g["mario_headers"])
        ).json()

        # 40 expenses of 100..139 cents, all paid by Mario, split with Luca.
        assert report["total_spent_cents"] == sum(100 + n for n in range(40))
        assert sum(entry["balance_cents"] for entry in report["balances"]) == 0


class TestExpenseCurrency:
    async def test_an_expense_takes_the_trip_currency(
        self, client: AsyncClient, auth_headers: dict
    ):
        """It used to take the column default, so every expense claimed to be
        in euro whatever the trip was kept in."""
        trip = (
            await client.post(
                TRIPS, json={"name": "Tokyo", "base_currency": "JPY"}, headers=auth_headers
            )
        ).json()
        me = (await client.get("/api/v1/auth/me", headers=auth_headers)).json()["id"]

        response = await client.post(
            f"{TRIPS}/{trip['id']}/expenses",
            json={
                "description": "Ramen",
                "amount_cents": 120000,
                "paid_by": me,
                "participants": [me],
            },
            headers=auth_headers,
        )

        assert response.status_code == 201
        assert response.json()["currency"] == "JPY"
