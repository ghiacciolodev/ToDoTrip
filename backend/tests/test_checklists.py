"""Checklist tests, including trip-boundary enforcement."""

from uuid import uuid4

from httpx import AsyncClient

TRIPS = "/api/v1/trips"


def _lists(trip_id: str) -> str:
    return f"{TRIPS}/{trip_id}/checklists"


async def _create_list(
    client: AsyncClient, trip_id: str, headers: dict, name: str = "Spesa"
) -> str:
    response = await client.post(_lists(trip_id), json={"name": name}, headers=headers)
    return response.json()["id"]


async def _add_entry(
    client: AsyncClient, trip_id: str, list_id: str, headers: dict, text: str
) -> str:
    response = await client.post(
        f"{_lists(trip_id)}/{list_id}/entries", json={"text": text}, headers=headers
    )
    return response.json()["id"]


class TestCreate:
    async def test_creates_an_empty_list(self, client: AsyncClient, trip: dict, auth_headers: dict):
        response = await client.post(
            _lists(trip["id"]), json={"name": "Spesa"}, headers=auth_headers
        )
        assert response.status_code == 201
        assert response.json()["entries"] == []

    async def test_blank_name_is_rejected(
        self, client: AsyncClient, trip: dict, auth_headers: dict
    ):
        response = await client.post(_lists(trip["id"]), json={"name": "   "}, headers=auth_headers)
        assert response.status_code == 422

    async def test_lists_carry_their_entries(
        self, client: AsyncClient, trip: dict, auth_headers: dict
    ):
        """The cards show progress before anyone opens a list."""
        list_id = await _create_list(client, trip["id"], auth_headers)
        await _add_entry(client, trip["id"], list_id, auth_headers, "Pane")
        await _add_entry(client, trip["id"], list_id, auth_headers, "Latte")

        response = await client.get(_lists(trip["id"]), headers=auth_headers)
        assert response.status_code == 200
        assert [e["text"] for e in response.json()[0]["entries"]] == ["Pane", "Latte"]


class TestIsolation:
    async def test_outsider_cannot_list(self, client: AsyncClient, trip: dict, other_headers: dict):
        response = await client.get(_lists(trip["id"]), headers=other_headers)
        assert response.status_code == 404

    async def test_outsider_cannot_create(
        self, client: AsyncClient, trip: dict, other_headers: dict
    ):
        response = await client.post(_lists(trip["id"]), json={"name": "X"}, headers=other_headers)
        assert response.status_code == 404

    async def test_list_id_does_not_cross_trips(
        self, client: AsyncClient, trip: dict, auth_headers: dict, other_headers: dict
    ):
        """Knowing a list id must not be enough to write to it from another trip."""
        list_id = await _create_list(client, trip["id"], auth_headers, "Segreta")

        theirs = await client.post(TRIPS, json={"name": "Altro"}, headers=other_headers)
        response = await client.post(
            f"{_lists(theirs.json()['id'])}/{list_id}/entries",
            json={"text": "X"},
            headers=other_headers,
        )
        assert response.status_code == 404


class TestEntries:
    async def test_blank_entry_is_rejected(
        self, client: AsyncClient, trip: dict, auth_headers: dict
    ):
        list_id = await _create_list(client, trip["id"], auth_headers)
        response = await client.post(
            f"{_lists(trip['id'])}/{list_id}/entries", json={"text": " "}, headers=auth_headers
        )
        assert response.status_code == 422

    async def test_entry_text_is_trimmed(self, client: AsyncClient, trip: dict, auth_headers: dict):
        list_id = await _create_list(client, trip["id"], auth_headers)
        response = await client.post(
            f"{_lists(trip['id'])}/{list_id}/entries", json={"text": " Pane "}, headers=auth_headers
        )
        assert response.json()["text"] == "Pane"

    async def test_unknown_list_returns_404(
        self, client: AsyncClient, trip: dict, auth_headers: dict
    ):
        response = await client.post(
            f"{_lists(trip['id'])}/{uuid4()}/entries", json={"text": "X"}, headers=auth_headers
        )
        assert response.status_code == 404

    async def test_entry_id_does_not_cross_lists(
        self, client: AsyncClient, trip: dict, auth_headers: dict
    ):
        first = await _create_list(client, trip["id"], auth_headers, "Spesa")
        second = await _create_list(client, trip["id"], auth_headers, "Farmacia")
        entry_id = await _add_entry(client, trip["id"], first, auth_headers, "Pane")

        response = await client.delete(
            f"{_lists(trip['id'])}/{second}/entries/{entry_id}", headers=auth_headers
        )
        assert response.status_code == 404

    async def test_deletes_an_entry(self, client: AsyncClient, trip: dict, auth_headers: dict):
        list_id = await _create_list(client, trip["id"], auth_headers)
        entry_id = await _add_entry(client, trip["id"], list_id, auth_headers, "Pane")

        deleted = await client.delete(
            f"{_lists(trip['id'])}/{list_id}/entries/{entry_id}", headers=auth_headers
        )
        assert deleted.status_code == 204

        remaining = await client.get(_lists(trip["id"]), headers=auth_headers)
        assert remaining.json()[0]["entries"] == []


class TestChecking:
    async def test_checking_records_who_and_when(
        self, client: AsyncClient, trip: dict, auth_headers: dict
    ):
        list_id = await _create_list(client, trip["id"], auth_headers)
        entry_id = await _add_entry(client, trip["id"], list_id, auth_headers, "Latte")

        response = await client.post(
            f"{_lists(trip['id'])}/{list_id}/entries/{entry_id}/check", headers=auth_headers
        )
        assert response.json()["checked_at"] is not None
        assert response.json()["checked_by"] is not None

    async def test_checking_twice_keeps_the_first_timestamp(
        self, client: AsyncClient, trip: dict, auth_headers: dict
    ):
        """Two people in the same aisle must not rewrite who got it."""
        list_id = await _create_list(client, trip["id"], auth_headers)
        entry_id = await _add_entry(client, trip["id"], list_id, auth_headers, "Latte")
        url = f"{_lists(trip['id'])}/{list_id}/entries/{entry_id}/check"

        first = await client.post(url, headers=auth_headers)
        second = await client.post(url, headers=auth_headers)
        assert first.json()["checked_at"] == second.json()["checked_at"]

    async def test_unchecking_clears_it(self, client: AsyncClient, trip: dict, auth_headers: dict):
        list_id = await _create_list(client, trip["id"], auth_headers)
        entry_id = await _add_entry(client, trip["id"], list_id, auth_headers, "Latte")
        url = f"{_lists(trip['id'])}/{list_id}/entries/{entry_id}/check"

        await client.post(url, headers=auth_headers)
        response = await client.delete(url, headers=auth_headers)
        assert response.json()["checked_at"] is None
        assert response.json()["checked_by"] is None

    async def test_a_member_sees_what_another_ticked(
        self,
        client: AsyncClient,
        trip: dict,
        invite_code: str,
        auth_headers: dict,
        other_headers: dict,
    ):
        await client.post(f"{TRIPS}/join", json={"code": invite_code}, headers=other_headers)
        list_id = await _create_list(client, trip["id"], auth_headers)
        entry_id = await _add_entry(client, trip["id"], list_id, auth_headers, "Latte")

        await client.post(
            f"{_lists(trip['id'])}/{list_id}/entries/{entry_id}/check", headers=other_headers
        )
        response = await client.get(_lists(trip["id"]), headers=auth_headers)
        assert response.json()[0]["entries"][0]["checked_at"] is not None


class TestDelete:
    async def test_deleting_a_list_takes_its_entries(
        self, client: AsyncClient, trip: dict, auth_headers: dict
    ):
        list_id = await _create_list(client, trip["id"], auth_headers)
        entry_id = await _add_entry(client, trip["id"], list_id, auth_headers, "Pane")

        deleted = await client.delete(f"{_lists(trip['id'])}/{list_id}", headers=auth_headers)
        assert deleted.status_code == 204

        orphaned = await client.post(
            f"{_lists(trip['id'])}/{list_id}/entries/{entry_id}/check", headers=auth_headers
        )
        assert orphaned.status_code == 404

    async def test_unknown_list_returns_404(
        self, client: AsyncClient, trip: dict, auth_headers: dict
    ):
        response = await client.delete(f"{_lists(trip['id'])}/{uuid4()}", headers=auth_headers)
        assert response.status_code == 404
