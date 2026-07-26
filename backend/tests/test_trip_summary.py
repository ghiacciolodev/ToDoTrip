"""The trips list carries what its cards draw.

Without these fields every card would fetch its own members and its own
balance: ten trips would be twenty-one requests, which a phone feels at once.
The risk of computing them separately is that the list and the money tab start
disagreeing, so most of what follows pins them to each other.
"""

from httpx import AsyncClient

TRIPS = "/api/v1/trips"


async def _id(client: AsyncClient, headers: dict) -> str:
    response = await client.get("/api/v1/auth/me", headers=headers)
    return response.json()["id"]


async def _expense(
    client: AsyncClient,
    trip_id: str,
    headers: dict,
    *,
    paid_by: str,
    participants: list[str],
    amount_cents: int = 6000,
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


class TestSummary:
    async def test_a_lone_trip_reports_one_member_and_no_balance(
        self, client: AsyncClient, trip: dict, auth_headers: dict
    ):
        response = await client.get(TRIPS, headers=auth_headers)
        row = response.json()[0]
        assert row["member_count"] == 1
        assert [m["display_name"] for m in row["member_preview"]] == ["Mario"]
        # Null, not zero: "nothing spent yet" is not "settled", and the card
        # says the two differently.
        assert row["my_balance_cents"] is None

    async def test_counts_and_previews_every_member(
        self,
        client: AsyncClient,
        trip: dict,
        invite_code: str,
        auth_headers: dict,
        other_headers: dict,
    ):
        await client.post(f"{TRIPS}/join", json={"code": invite_code}, headers=other_headers)

        row = (await client.get(TRIPS, headers=auth_headers)).json()[0]
        assert row["member_count"] == 2
        # Oldest first, so the owner leads the avatars.
        assert [m["display_name"] for m in row["member_preview"]] == ["Mario", "Luca"]

    async def test_preview_stops_at_three(
        self, client: AsyncClient, trip: dict, invite_code: str, auth_headers: dict
    ):
        for index in range(4):
            user = {
                "email": f"extra{index}@test.it",
                "password": "password123",
                "display_name": f"Extra {index}",
            }
            await client.post("/api/v1/auth/register", json=user)
            login = await client.post(
                "/api/v1/auth/login",
                json={"email": user["email"], "password": user["password"]},
            )
            headers = {"Authorization": f"Bearer {login.json()['access_token']}"}
            await client.post(f"{TRIPS}/join", json={"code": invite_code}, headers=headers)

        row = (await client.get(TRIPS, headers=auth_headers)).json()[0]
        assert row["member_count"] == 5
        # Three avatars plus a count is what the card draws.
        assert len(row["member_preview"]) == 3

    async def test_balance_matches_the_full_report(
        self,
        client: AsyncClient,
        trip: dict,
        invite_code: str,
        auth_headers: dict,
        other_headers: dict,
    ):
        """The list and the money tab must never disagree about what you are owed."""
        await client.post(f"{TRIPS}/join", json={"code": invite_code}, headers=other_headers)
        mine_id = await _id(client, auth_headers)
        theirs_id = await _id(client, other_headers)
        await _expense(
            client,
            trip["id"],
            auth_headers,
            paid_by=mine_id,
            participants=[mine_id, theirs_id],
        )

        summary = await client.get(TRIPS, headers=auth_headers)
        report = await client.get(f"{TRIPS}/{trip['id']}/balance", headers=auth_headers)
        from_report = next(
            b["balance_cents"] for b in report.json()["balances"] if b["user_id"] == mine_id
        )
        assert summary.json()[0]["my_balance_cents"] == from_report == 3000

        # And the other side sees the mirror image.
        theirs = await client.get(TRIPS, headers=other_headers)
        assert theirs.json()[0]["my_balance_cents"] == -3000

    async def test_a_repayment_moves_it(
        self,
        client: AsyncClient,
        trip: dict,
        invite_code: str,
        auth_headers: dict,
        other_headers: dict,
    ):
        await client.post(f"{TRIPS}/join", json={"code": invite_code}, headers=other_headers)
        mine_id = await _id(client, auth_headers)
        theirs_id = await _id(client, other_headers)
        await _expense(
            client,
            trip["id"],
            auth_headers,
            paid_by=mine_id,
            participants=[mine_id, theirs_id],
        )
        await client.post(
            f"{TRIPS}/{trip['id']}/settlements",
            json={"to_user_id": mine_id, "amount_cents": 3000},
            headers=other_headers,
        )

        assert (await client.get(TRIPS, headers=auth_headers)).json()[0]["my_balance_cents"] == 0

    async def test_spending_between_others_is_not_your_debt(
        self,
        client: AsyncClient,
        trip: dict,
        invite_code: str,
        auth_headers: dict,
        other_headers: dict,
    ):
        await client.post(f"{TRIPS}/join", json={"code": invite_code}, headers=other_headers)
        theirs_id = await _id(client, other_headers)
        await _expense(
            client,
            trip["id"],
            other_headers,
            paid_by=theirs_id,
            participants=[theirs_id],
            amount_cents=1000,
        )

        # Zero, not null: this trip has spending, just none of it yours.
        assert (await client.get(TRIPS, headers=auth_headers)).json()[0]["my_balance_cents"] == 0

    async def test_trips_do_not_leak_into_each_other(
        self, client: AsyncClient, trip: dict, auth_headers: dict
    ):
        mine_id = await _id(client, auth_headers)
        second = await client.post(TRIPS, json={"name": "Secondo"}, headers=auth_headers)
        await _expense(
            client,
            trip["id"],
            auth_headers,
            paid_by=mine_id,
            participants=[mine_id],
            amount_cents=2000,
        )

        rows = {
            r["id"]: r["my_balance_cents"]
            for r in (await client.get(TRIPS, headers=auth_headers)).json()
        }
        assert rows[trip["id"]] == 0
        assert rows[second.json()["id"]] is None


class TestLastActivity:
    """The line the card ends on, and the order the cards come in.

    It is deliberately not `trips.updated_at`: renaming a trip is not the only
    thing that happens in it, and a group that has been splitting bills all week
    would otherwise read as untouched since the day it was created.
    """

    async def _activity(self, client: AsyncClient, headers: dict, trip_id: str) -> str:
        rows = (await client.get(TRIPS, headers=headers)).json()
        return next(row["last_activity_at"] for row in rows if row["id"] == trip_id)

    async def test_an_empty_trip_still_has_one(
        self, client: AsyncClient, trip: dict, auth_headers: dict
    ):
        """Its own row is one of the sources, so the card never has a blank line."""
        assert (await self._activity(client, auth_headers, trip["id"])) is not None

    async def test_an_expense_counts(self, client: AsyncClient, trip: dict, auth_headers: dict):
        before = await self._activity(client, auth_headers, trip["id"])
        mine_id = await _id(client, auth_headers)
        await _expense(client, trip["id"], auth_headers, paid_by=mine_id, participants=[mine_id])
        assert (await self._activity(client, auth_headers, trip["id"])) > before

    async def test_ticking_a_list_entry_counts(
        self, client: AsyncClient, trip: dict, auth_headers: dict
    ):
        """Entries have no updated_at of their own, and ticking one is the most
        frequent thing anybody does in a trip."""
        checklist = await client.post(
            f"{TRIPS}/{trip['id']}/checklists", json={"name": "Spesa"}, headers=auth_headers
        )
        entry = await client.post(
            f"{TRIPS}/{trip['id']}/checklists/{checklist.json()['id']}/entries",
            json={"text": "Pane"},
            headers=auth_headers,
        )
        before = await self._activity(client, auth_headers, trip["id"])

        await client.post(
            f"{TRIPS}/{trip['id']}/checklists/{checklist.json()['id']}"
            f"/entries/{entry.json()['id']}/check",
            headers=auth_headers,
        )
        assert (await self._activity(client, auth_headers, trip["id"])) > before

    async def test_the_most_recently_touched_comes_first(
        self, client: AsyncClient, trip: dict, auth_headers: dict
    ):
        """The trip someone was just in is the one they want at the top, not the
        one whose departure date happens to be furthest out."""
        second = await client.post(TRIPS, json={"name": "Secondo"}, headers=auth_headers)
        assert (await client.get(TRIPS, headers=auth_headers)).json()[0]["id"] == second.json()[
            "id"
        ]

        await client.post(
            f"{TRIPS}/{trip['id']}/items",
            json={"type": "task", "title": "Prenotare"},
            headers=auth_headers,
        )
        assert (await client.get(TRIPS, headers=auth_headers)).json()[0]["id"] == trip["id"]

    async def test_activity_elsewhere_does_not_bump_this_one(
        self, client: AsyncClient, trip: dict, auth_headers: dict
    ):
        second = await client.post(TRIPS, json={"name": "Secondo"}, headers=auth_headers)
        before = await self._activity(client, auth_headers, trip["id"])

        await client.post(
            f"{TRIPS}/{second.json()['id']}/items",
            json={"type": "task", "title": "Prenotare"},
            headers=auth_headers,
        )
        assert (await self._activity(client, auth_headers, trip["id"])) == before


class TestIconAndColour:
    async def test_stored_and_returned(self, client: AsyncClient, auth_headers: dict):
        created = await client.post(
            TRIPS,
            json={"name": "Lisbona", "icon": "beach", "color": "teal"},
            headers=auth_headers,
        )
        assert created.status_code == 201
        assert (created.json()["icon"], created.json()["color"]) == ("beach", "teal")

    async def test_absent_means_the_client_derives_one(self, trip: dict):
        """Null rather than a stored default: the client picks from the trip id,
        the way avatars already do, so no trip is ever grey."""
        assert trip["icon"] is None
        assert trip["color"] is None

    async def test_owner_can_change_them(self, client: AsyncClient, trip: dict, auth_headers: dict):
        response = await client.patch(
            f"{TRIPS}/{trip['id']}",
            json={"icon": "mountain", "color": "terracotta"},
            headers=auth_headers,
        )
        assert (response.json()["icon"], response.json()["color"]) == (
            "mountain",
            "terracotta",
        )

    async def test_a_member_cannot(
        self, client: AsyncClient, trip: dict, invite_code: str, other_headers: dict
    ):
        await client.post(f"{TRIPS}/join", json={"code": invite_code}, headers=other_headers)
        response = await client.patch(
            f"{TRIPS}/{trip['id']}", json={"icon": "party"}, headers=other_headers
        )
        assert response.status_code == 403

    async def test_a_patch_leaves_the_other_alone(
        self, client: AsyncClient, trip: dict, auth_headers: dict
    ):
        await client.patch(
            f"{TRIPS}/{trip['id']}",
            json={"icon": "sail", "color": "teal"},
            headers=auth_headers,
        )
        response = await client.patch(
            f"{TRIPS}/{trip['id']}", json={"icon": "ski"}, headers=auth_headers
        )
        assert response.json()["color"] == "teal"
