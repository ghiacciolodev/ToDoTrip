"""Calendar and task tests, including trip-boundary enforcement."""

from datetime import UTC, datetime, timedelta
from uuid import uuid4

from httpx import AsyncClient

TRIPS = "/api/v1/trips"


def _items(trip_id: str) -> str:
    return f"{TRIPS}/{trip_id}/items"


def _at(days: int) -> str:
    return (datetime.now(UTC) + timedelta(days=days)).isoformat()


class TestCreate:
    async def test_creates_an_event(self, client: AsyncClient, trip: dict, auth_headers: dict):
        response = await client.post(
            _items(trip["id"]),
            json={"type": "event", "title": "Volo per Lisbona", "starts_at": _at(10)},
            headers=auth_headers,
        )
        assert response.status_code == 201
        assert response.json()["type"] == "event"

    async def test_creates_a_task(self, client: AsyncClient, trip: dict, auth_headers: dict):
        response = await client.post(
            _items(trip["id"]),
            json={"type": "task", "title": "Fare la spesa"},
            headers=auth_headers,
        )
        assert response.status_code == 201
        assert response.json()["completed_at"] is None

    async def test_event_without_a_date_is_rejected(
        self, client: AsyncClient, trip: dict, auth_headers: dict
    ):
        """An undated event could never be placed on a calendar."""
        response = await client.post(
            _items(trip["id"]), json={"type": "event", "title": "X"}, headers=auth_headers
        )
        assert response.status_code == 422

    async def test_reversed_range_is_rejected(
        self, client: AsyncClient, trip: dict, auth_headers: dict
    ):
        response = await client.post(
            _items(trip["id"]),
            json={"type": "event", "title": "X", "starts_at": _at(10), "ends_at": _at(9)},
            headers=auth_headers,
        )
        assert response.status_code == 422

    async def test_events_cannot_be_assigned(
        self, client: AsyncClient, trip: dict, auth_headers: dict
    ):
        response = await client.post(
            _items(trip["id"]),
            json={
                "type": "event",
                "title": "X",
                "starts_at": _at(1),
                "assigned_to": [str(uuid4())],
            },
            headers=auth_headers,
        )
        assert response.status_code == 422

    async def test_assignee_must_be_a_member(
        self, client: AsyncClient, trip: dict, auth_headers: dict, other_headers: dict
    ):
        """Work cannot be handed to someone outside the group."""
        outsider = await client.get("/api/v1/auth/me", headers=other_headers)
        response = await client.post(
            _items(trip["id"]),
            json={"type": "task", "title": "X", "assigned_to": [outsider.json()["id"]]},
            headers=auth_headers,
        )
        assert response.status_code == 422

    async def test_assignee_can_be_a_member(
        self,
        client: AsyncClient,
        trip: dict,
        invite_code: str,
        auth_headers: dict,
        other_headers: dict,
    ):
        await client.post(f"{TRIPS}/join", json={"code": invite_code}, headers=other_headers)
        member = await client.get("/api/v1/auth/me", headers=other_headers)
        response = await client.post(
            _items(trip["id"]),
            json={"type": "task", "title": "X", "assigned_to": [member.json()["id"]]},
            headers=auth_headers,
        )
        assert response.status_code == 201


class TestIsolation:
    async def test_outsider_cannot_list(self, client: AsyncClient, trip: dict, other_headers: dict):
        response = await client.get(_items(trip["id"]), headers=other_headers)
        assert response.status_code == 404

    async def test_outsider_cannot_create(
        self, client: AsyncClient, trip: dict, other_headers: dict
    ):
        response = await client.post(
            _items(trip["id"]), json={"type": "task", "title": "X"}, headers=other_headers
        )
        assert response.status_code == 404

    async def test_item_id_does_not_cross_trips(
        self, client: AsyncClient, trip: dict, auth_headers: dict, other_headers: dict
    ):
        """Knowing an item id must not be enough to read it from another trip."""
        created = await client.post(
            _items(trip["id"]), json={"type": "task", "title": "Segreto"}, headers=auth_headers
        )
        item_id = created.json()["id"]

        theirs = await client.post(TRIPS, json={"name": "Altro"}, headers=other_headers)
        response = await client.get(
            f"{_items(theirs.json()['id'])}/{item_id}", headers=other_headers
        )
        assert response.status_code == 404


class TestFilters:
    async def test_filters_by_type(self, client: AsyncClient, trip: dict, auth_headers: dict):
        await client.post(
            _items(trip["id"]),
            json={"type": "event", "title": "Volo", "starts_at": _at(5)},
            headers=auth_headers,
        )
        await client.post(
            _items(trip["id"]), json={"type": "task", "title": "Spesa"}, headers=auth_headers
        )
        response = await client.get(
            _items(trip["id"]), params={"type": "task"}, headers=auth_headers
        )
        assert response.status_code == 200
        assert [i["title"] for i in response.json()] == ["Spesa"]

    async def test_filters_by_completion(self, client: AsyncClient, trip: dict, auth_headers: dict):
        created = await client.post(
            _items(trip["id"]), json={"type": "task", "title": "Fatto"}, headers=auth_headers
        )
        await client.post(
            _items(trip["id"]), json={"type": "task", "title": "Da fare"}, headers=auth_headers
        )
        await client.post(
            f"{_items(trip['id'])}/{created.json()['id']}/complete", headers=auth_headers
        )
        response = await client.get(
            _items(trip["id"]), params={"completed": "false"}, headers=auth_headers
        )
        assert response.status_code == 200
        assert [i["title"] for i in response.json()] == ["Da fare"]

    async def test_filters_by_date_window(
        self, client: AsyncClient, trip: dict, auth_headers: dict
    ):
        await client.post(
            _items(trip["id"]),
            json={"type": "event", "title": "Presto", "starts_at": _at(1)},
            headers=auth_headers,
        )
        await client.post(
            _items(trip["id"]),
            json={"type": "event", "title": "Tardi", "starts_at": _at(30)},
            headers=auth_headers,
        )
        # params= lets httpx percent-encode the value: the "+" of the UTC offset
        # would otherwise be decoded as a space and the date rejected.
        response = await client.get(
            _items(trip["id"]), params={"starts_before": _at(7)}, headers=auth_headers
        )
        assert response.status_code == 200
        assert [i["title"] for i in response.json()] == ["Presto"]

    async def test_undated_items_sort_last(
        self, client: AsyncClient, trip: dict, auth_headers: dict
    ):
        """The calendar comes first, the undated backlog after."""
        await client.post(
            _items(trip["id"]), json={"type": "task", "title": "Backlog"}, headers=auth_headers
        )
        await client.post(
            _items(trip["id"]),
            json={"type": "event", "title": "Volo", "starts_at": _at(3)},
            headers=auth_headers,
        )
        response = await client.get(_items(trip["id"]), headers=auth_headers)
        assert [i["title"] for i in response.json()] == ["Volo", "Backlog"]


class TestUpdate:
    async def test_patches_a_field(self, client: AsyncClient, trip: dict, auth_headers: dict):
        created = await client.post(
            _items(trip["id"]), json={"type": "task", "title": "Vecchio"}, headers=auth_headers
        )
        response = await client.patch(
            f"{_items(trip['id'])}/{created.json()['id']}",
            json={"title": "Nuovo"},
            headers=auth_headers,
        )
        assert response.json()["title"] == "Nuovo"

    async def test_unknown_item_returns_404(
        self, client: AsyncClient, trip: dict, auth_headers: dict
    ):
        response = await client.patch(
            f"{_items(trip['id'])}/{uuid4()}", json={"title": "X"}, headers=auth_headers
        )
        assert response.status_code == 404

    async def test_deletes(self, client: AsyncClient, trip: dict, auth_headers: dict):
        created = await client.post(
            _items(trip["id"]), json={"type": "task", "title": "X"}, headers=auth_headers
        )
        url = f"{_items(trip['id'])}/{created.json()['id']}"

        deleted = await client.delete(url, headers=auth_headers)
        assert deleted.status_code == 204

        gone = await client.get(url, headers=auth_headers)
        assert gone.status_code == 404


class TestCompletion:
    async def test_completing_records_who_and_when(
        self, client: AsyncClient, trip: dict, auth_headers: dict
    ):
        created = await client.post(
            _items(trip["id"]), json={"type": "task", "title": "X"}, headers=auth_headers
        )
        response = await client.post(
            f"{_items(trip['id'])}/{created.json()['id']}/complete", headers=auth_headers
        )
        assert response.json()["completed_at"] is not None
        assert response.json()["completed_by"] is not None

    async def test_completing_twice_keeps_the_first_timestamp(
        self, client: AsyncClient, trip: dict, auth_headers: dict
    ):
        """Re-tapping a checkbox must not rewrite history."""
        created = await client.post(
            _items(trip["id"]), json={"type": "task", "title": "X"}, headers=auth_headers
        )
        url = f"{_items(trip['id'])}/{created.json()['id']}/complete"

        first = await client.post(url, headers=auth_headers)
        second = await client.post(url, headers=auth_headers)
        assert first.json()["completed_at"] == second.json()["completed_at"]

    async def test_reopening_clears_completion(
        self, client: AsyncClient, trip: dict, auth_headers: dict
    ):
        created = await client.post(
            _items(trip["id"]), json={"type": "task", "title": "X"}, headers=auth_headers
        )
        url = f"{_items(trip['id'])}/{created.json()['id']}/complete"

        await client.post(url, headers=auth_headers)
        response = await client.delete(url, headers=auth_headers)
        assert response.json()["completed_at"] is None
        assert response.json()["completed_by"] is None

    async def test_events_cannot_be_completed(
        self, client: AsyncClient, trip: dict, auth_headers: dict
    ):
        created = await client.post(
            _items(trip["id"]),
            json={"type": "event", "title": "Volo", "starts_at": _at(2)},
            headers=auth_headers,
        )
        response = await client.post(
            f"{_items(trip['id'])}/{created.json()['id']}/complete", headers=auth_headers
        )
        assert response.status_code == 409
