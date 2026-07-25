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
        json={"email": "anna@test.it", "password": "password123", "display_name": "Anna"},
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
