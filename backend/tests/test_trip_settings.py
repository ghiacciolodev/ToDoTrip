"""Archiving, per-member muting, the detail aggregates and the CSV export.

The one that matters most is archiving. Its whole meaning is "nothing more goes
in here", and a rule enforced only by hidden buttons is not a rule: an older
client, a retried request, or anybody with a terminal would keep writing into a
trip the group agreed was finished.
"""

from httpx import AsyncClient

AUTH = "/api/v1/auth"
TRIPS = "/api/v1/trips"


async def _id(client: AsyncClient, headers: dict) -> str:
    return (await client.get(f"{AUTH}/me", headers=headers)).json()["id"]


async def _expense(
    client: AsyncClient,
    trip_id: str,
    headers: dict,
    *,
    paid_by: str,
    participants: list[str],
    amount_cents: int = 6000,
    description: str = "Cena",
) -> None:
    await client.post(
        f"{TRIPS}/{trip_id}/expenses",
        json={
            "description": description,
            "amount_cents": amount_cents,
            "paid_by": paid_by,
            "participants": participants,
        },
        headers=headers,
    )


async def _archive(client: AsyncClient, trip_id: str, headers: dict, value: bool = True):
    return await client.patch(f"{TRIPS}/{trip_id}", json={"archived": value}, headers=headers)


class TestArchiving:
    async def test_archiving_sets_a_timestamp(
        self, client: AsyncClient, trip: dict, auth_headers: dict
    ):
        assert trip["archived_at"] is None
        response = await _archive(client, trip["id"], auth_headers)
        assert response.status_code == 200
        assert response.json()["archived_at"] is not None

    async def test_it_leaves_the_active_list_and_appears_in_the_other(
        self, client: AsyncClient, trip: dict, auth_headers: dict
    ):
        await _archive(client, trip["id"], auth_headers)

        active = await client.get(TRIPS, headers=auth_headers)
        assert active.json() == []
        archived = await client.get(f"{TRIPS}?archived=true", headers=auth_headers)
        assert [row["id"] for row in archived.json()] == [trip["id"]]

    async def test_unarchiving_brings_it_back(
        self, client: AsyncClient, trip: dict, auth_headers: dict
    ):
        await _archive(client, trip["id"], auth_headers)
        response = await _archive(client, trip["id"], auth_headers, value=False)

        assert response.json()["archived_at"] is None
        assert [row["id"] for row in (await client.get(TRIPS, headers=auth_headers)).json()] == [
            trip["id"]
        ]

    async def test_archiving_twice_keeps_the_first_date(
        self, client: AsyncClient, trip: dict, auth_headers: dict
    ):
        """When it was put away is a fact; a stray second tap must not rewrite it."""
        first = (await _archive(client, trip["id"], auth_headers)).json()["archived_at"]
        second = (await _archive(client, trip["id"], auth_headers)).json()["archived_at"]
        assert first == second

    async def test_only_the_owner_can_archive(
        self, client: AsyncClient, trip: dict, invite_code: str, other_headers: dict
    ):
        await client.post(f"{TRIPS}/join", json={"code": invite_code}, headers=other_headers)
        assert (await _archive(client, trip["id"], other_headers)).status_code == 403


class TestArchivedIsReadOnly:
    """Every way content gets into a trip has to be closed, not just the ones
    with a button on the settings screen."""

    async def test_it_stays_readable(self, client: AsyncClient, trip: dict, auth_headers: dict):
        """The point of keeping an archived trip is going back and looking at it."""
        await _archive(client, trip["id"], auth_headers)

        assert (await client.get(f"{TRIPS}/{trip['id']}", headers=auth_headers)).status_code == 200
        for path in ("items", "expenses", "checklists", "balance", "members"):
            response = await client.get(f"{TRIPS}/{trip['id']}/{path}", headers=auth_headers)
            assert response.status_code == 200, path

    async def test_no_new_expense(self, client: AsyncClient, trip: dict, auth_headers: dict):
        mine = await _id(client, auth_headers)
        await _archive(client, trip["id"], auth_headers)

        response = await client.post(
            f"{TRIPS}/{trip['id']}/expenses",
            json={
                "description": "Cena",
                "amount_cents": 1000,
                "paid_by": mine,
                "participants": [mine],
            },
            headers=auth_headers,
        )
        assert response.status_code == 409
        assert response.json()["detail"]["code"] == "trip_archived"

    async def test_no_new_item(self, client: AsyncClient, trip: dict, auth_headers: dict):
        await _archive(client, trip["id"], auth_headers)
        response = await client.post(
            f"{TRIPS}/{trip['id']}/items",
            json={"type": "task", "title": "Prenotare"},
            headers=auth_headers,
        )
        assert response.status_code == 409

    async def test_no_new_checklist(self, client: AsyncClient, trip: dict, auth_headers: dict):
        await _archive(client, trip["id"], auth_headers)
        response = await client.post(
            f"{TRIPS}/{trip['id']}/checklists", json={"name": "Spesa"}, headers=auth_headers
        )
        assert response.status_code == 409

    async def test_no_new_pin(self, client: AsyncClient, trip: dict, auth_headers: dict):
        await _archive(client, trip["id"], auth_headers)
        response = await client.post(
            f"{TRIPS}/{trip['id']}/pins",
            json={"name": "Ostello", "latitude": 38.7, "longitude": -9.1, "category": "lodging"},
            headers=auth_headers,
        )
        assert response.status_code == 409

    async def test_existing_content_cannot_be_edited_either(
        self, client: AsyncClient, trip: dict, auth_headers: dict
    ):
        """Ticking a task off is a write too, and a closed trip should not change."""
        item = await client.post(
            f"{TRIPS}/{trip['id']}/items",
            json={"type": "task", "title": "Prenotare"},
            headers=auth_headers,
        )
        item_id = item.json()["id"]
        await _archive(client, trip["id"], auth_headers)

        assert (
            await client.post(
                f"{TRIPS}/{trip['id']}/items/{item_id}/complete", headers=auth_headers
            )
        ).status_code == 409
        assert (
            await client.delete(f"{TRIPS}/{trip['id']}/items/{item_id}", headers=auth_headers)
        ).status_code == 409

    async def test_unarchiving_reopens_the_door(
        self, client: AsyncClient, trip: dict, auth_headers: dict
    ):
        await _archive(client, trip["id"], auth_headers)
        await _archive(client, trip["id"], auth_headers, value=False)

        response = await client.post(
            f"{TRIPS}/{trip['id']}/items",
            json={"type": "task", "title": "Prenotare"},
            headers=auth_headers,
        )
        assert response.status_code == 201

    async def test_the_trip_itself_can_still_be_edited(
        self, client: AsyncClient, trip: dict, auth_headers: dict
    ):
        """Otherwise unarchiving would be impossible: the way back out is a PATCH
        on the trip, so the trip is not what gets frozen — its contents are."""
        await _archive(client, trip["id"], auth_headers)
        assert (
            await client.patch(
                f"{TRIPS}/{trip['id']}", json={"name": "Lisbona 2025"}, headers=auth_headers
            )
        ).status_code == 200


class TestDetailAggregates:
    async def test_an_empty_trip_counts_one_member_and_nothing_else(
        self, client: AsyncClient, trip: dict, auth_headers: dict
    ):
        detail = (await client.get(f"{TRIPS}/{trip['id']}", headers=auth_headers)).json()
        assert detail["member_count"] == 1
        assert detail["expense_count"] == 0
        assert detail["item_count"] == 0
        assert detail["total_spent_cents"] == 0
        assert detail["created_by_name"] == "Mario"

    async def test_it_counts_what_is_in_there(
        self,
        client: AsyncClient,
        trip: dict,
        invite_code: str,
        auth_headers: dict,
        other_headers: dict,
    ):
        await client.post(f"{TRIPS}/join", json={"code": invite_code}, headers=other_headers)
        mine = await _id(client, auth_headers)
        theirs = await _id(client, other_headers)
        await _expense(client, trip["id"], auth_headers, paid_by=mine, participants=[mine, theirs])
        await _expense(
            client,
            trip["id"],
            auth_headers,
            paid_by=mine,
            participants=[mine],
            amount_cents=1500,
        )
        await client.post(
            f"{TRIPS}/{trip['id']}/items",
            json={"type": "task", "title": "Prenotare"},
            headers=auth_headers,
        )

        detail = (await client.get(f"{TRIPS}/{trip['id']}", headers=auth_headers)).json()
        assert detail["member_count"] == 2
        assert detail["expense_count"] == 2
        assert detail["item_count"] == 1
        assert detail["total_spent_cents"] == 7500

    async def test_a_repayment_is_not_spending(
        self,
        client: AsyncClient,
        trip: dict,
        invite_code: str,
        auth_headers: dict,
        other_headers: dict,
    ):
        """A settlement moves money between two people; it is not part of what
        the trip cost, and adding it would double-count."""
        await client.post(f"{TRIPS}/join", json={"code": invite_code}, headers=other_headers)
        mine = await _id(client, auth_headers)
        theirs = await _id(client, other_headers)
        await _expense(client, trip["id"], auth_headers, paid_by=mine, participants=[mine, theirs])
        await client.post(
            f"{TRIPS}/{trip['id']}/settlements",
            json={"to_user_id": mine, "amount_cents": 3000},
            headers=other_headers,
        )

        detail = (await client.get(f"{TRIPS}/{trip['id']}", headers=auth_headers)).json()
        assert detail["total_spent_cents"] == 6000

    async def test_a_stranger_still_gets_404(
        self, client: AsyncClient, trip: dict, other_headers: dict
    ):
        assert (await client.get(f"{TRIPS}/{trip['id']}", headers=other_headers)).status_code == 404


class TestMuting:
    async def test_it_starts_off_and_can_be_turned_on(
        self, client: AsyncClient, trip: dict, auth_headers: dict
    ):
        path = f"{TRIPS}/{trip['id']}/members/me/settings"
        assert (await client.get(path, headers=auth_headers)).json()["muted"] is False

        assert (await client.patch(path, json={"muted": True}, headers=auth_headers)).json()[
            "muted"
        ] is True
        assert (await client.get(path, headers=auth_headers)).json()["muted"] is True

    async def test_it_is_mine_alone(
        self,
        client: AsyncClient,
        trip: dict,
        invite_code: str,
        auth_headers: dict,
        other_headers: dict,
    ):
        """The reason it lives on the membership and not on the trip: muting a
        group for everybody is not what anyone reaching for that switch means."""
        await client.post(f"{TRIPS}/join", json={"code": invite_code}, headers=other_headers)
        path = f"{TRIPS}/{trip['id']}/members/me/settings"

        await client.patch(path, json={"muted": True}, headers=auth_headers)
        assert (await client.get(path, headers=other_headers)).json()["muted"] is False

    async def test_a_stranger_cannot_see_it(
        self, client: AsyncClient, trip: dict, other_headers: dict
    ):
        response = await client.get(
            f"{TRIPS}/{trip['id']}/members/me/settings", headers=other_headers
        )
        assert response.status_code == 404


class TestExport:
    async def test_it_has_a_row_per_expense_and_a_column_per_person(
        self,
        client: AsyncClient,
        trip: dict,
        invite_code: str,
        auth_headers: dict,
        other_headers: dict,
    ):
        await client.post(f"{TRIPS}/join", json={"code": invite_code}, headers=other_headers)
        mine = await _id(client, auth_headers)
        theirs = await _id(client, other_headers)
        await _expense(client, trip["id"], auth_headers, paid_by=mine, participants=[mine, theirs])

        response = await client.get(f"{TRIPS}/{trip['id']}/export.csv", headers=auth_headers)
        assert response.status_code == 200
        lines = response.text.lstrip("﻿").strip().split("\r\n")

        assert lines[0] == "Date,Description,Paid by,Amount (EUR),Mario (EUR),Luca (EUR)"
        assert lines[1].endswith("Cena,Mario,60.00,30.00,30.00")
        # A total row, so the file answers "what did this cost" without a formula.
        assert lines[-1] == ",Total,,60.00,30.00,30.00"

    async def test_someone_left_out_of_an_expense_gets_a_blank_not_a_zero(
        self,
        client: AsyncClient,
        trip: dict,
        invite_code: str,
        auth_headers: dict,
        other_headers: dict,
    ):
        """ "Did not take part" and "owes nothing" are different facts."""
        await client.post(f"{TRIPS}/join", json={"code": invite_code}, headers=other_headers)
        mine = await _id(client, auth_headers)
        await _expense(
            client, trip["id"], auth_headers, paid_by=mine, participants=[mine], amount_cents=1000
        )

        response = await client.get(f"{TRIPS}/{trip['id']}/export.csv", headers=auth_headers)
        assert response.text.strip().split("\r\n")[1].endswith("Cena,Mario,10.00,10.00,")

    async def test_a_formula_in_a_description_is_defused(
        self, client: AsyncClient, trip: dict, auth_headers: dict
    ):
        """A description is text. Excel would run it as a formula on whoever
        opens the file, which makes this the export's one real attack surface.
        """
        mine = await _id(client, auth_headers)
        await _expense(
            client,
            trip["id"],
            auth_headers,
            paid_by=mine,
            participants=[mine],
            description="=1+1",
        )

        response = await client.get(f"{TRIPS}/{trip['id']}/export.csv", headers=auth_headers)
        assert "'=1+1" in response.text
        assert ",=1+1," not in response.text

    async def test_the_filename_carries_the_trip_name(
        self, client: AsyncClient, trip: dict, auth_headers: dict
    ):
        response = await client.get(f"{TRIPS}/{trip['id']}/export.csv", headers=auth_headers)
        assert "Lisbona-2026-expenses.csv" in response.headers["content-disposition"]

    async def test_a_quote_in_the_name_cannot_break_the_header(
        self, client: AsyncClient, auth_headers: dict
    ):
        """Trip names are free text and end up in a response header."""
        created = await client.post(TRIPS, json={"name": 'Lisbona "2026"\nX'}, headers=auth_headers)
        response = await client.get(
            f"{TRIPS}/{created.json()['id']}/export.csv", headers=auth_headers
        )
        header = response.headers["content-disposition"]
        assert "\n" not in header
        assert header.startswith('attachment; filename="Lisbona-2026-X-expenses.csv"')

    async def test_any_member_may_download_it(
        self, client: AsyncClient, trip: dict, invite_code: str, other_headers: dict
    ):
        """Everybody's own money is in it, and it shows nothing the app does not."""
        await client.post(f"{TRIPS}/join", json={"code": invite_code}, headers=other_headers)
        assert (
            await client.get(f"{TRIPS}/{trip['id']}/export.csv", headers=other_headers)
        ).status_code == 200

    async def test_a_stranger_may_not(self, client: AsyncClient, trip: dict, other_headers: dict):
        assert (
            await client.get(f"{TRIPS}/{trip['id']}/export.csv", headers=other_headers)
        ).status_code == 404

    async def test_an_empty_trip_exports_just_the_header(
        self, client: AsyncClient, trip: dict, auth_headers: dict
    ):
        response = await client.get(f"{TRIPS}/{trip['id']}/export.csv", headers=auth_headers)
        assert response.text.lstrip("﻿").strip() == (
            "Date,Description,Paid by,Amount (EUR),Mario (EUR)"
        )

    async def test_an_archived_trip_can_still_be_exported(
        self, client: AsyncClient, trip: dict, auth_headers: dict
    ):
        """Reading is exactly what an archived trip is for."""
        await _archive(client, trip["id"], auth_headers)
        assert (
            await client.get(f"{TRIPS}/{trip['id']}/export.csv", headers=auth_headers)
        ).status_code == 200
