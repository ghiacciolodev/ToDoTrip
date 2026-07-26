"""Map tests: live locations and shared pins.

Locations are the only ephemeral data in the app, so most of what matters here
is what happens when they get old or when someone stops sharing.
"""

from datetime import UTC, datetime, timedelta
from uuid import uuid4

from httpx import AsyncClient
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models import MemberLocation

TRIPS = "/api/v1/trips"

LISBON = {"latitude": 38.7223, "longitude": -9.1393, "accuracy_m": 12.5}
PORTO = {"latitude": 41.1579, "longitude": -8.6291}


class TestLocationSharing:
    async def test_reports_a_position(self, client: AsyncClient, trip: dict, auth_headers: dict):
        response = await client.put(
            f"{TRIPS}/{trip['id']}/location", json=LISBON, headers=auth_headers
        )
        assert response.status_code == 200
        assert response.json()["latitude"] == LISBON["latitude"]
        # The TTL is what stops a closed app from looking like a live position.
        assert response.json()["expires_at"] > datetime.now(UTC).isoformat()

    async def test_a_second_report_overwrites_the_first(
        self, client: AsyncClient, trip: dict, auth_headers: dict, db: AsyncSession
    ):
        """One row per member: this is a position, not a trail."""
        await client.put(f"{TRIPS}/{trip['id']}/location", json=LISBON, headers=auth_headers)
        await client.put(f"{TRIPS}/{trip['id']}/location", json=PORTO, headers=auth_headers)

        rows = (
            (await db.execute(select(MemberLocation).where(MemberLocation.trip_id == trip["id"])))
            .scalars()
            .all()
        )
        assert len(rows) == 1
        assert rows[0].latitude == PORTO["latitude"]
        # Left unset by the second report, so the stale accuracy must not linger.
        assert rows[0].accuracy_m is None

    async def test_stale_positions_are_not_returned(
        self, client: AsyncClient, trip: dict, auth_headers: dict, db: AsyncSession
    ):
        """Someone who closed the app two hours ago is not where they were."""
        await client.put(f"{TRIPS}/{trip['id']}/location", json=LISBON, headers=auth_headers)

        row = await db.scalar(select(MemberLocation).where(MemberLocation.trip_id == trip["id"]))
        row.expires_at = datetime.now(UTC) - timedelta(minutes=1)
        await db.commit()

        response = await client.get(f"{TRIPS}/{trip['id']}/locations", headers=auth_headers)
        assert response.json() == []

    async def test_stopping_removes_the_row(
        self, client: AsyncClient, trip: dict, auth_headers: dict, db: AsyncSession
    ):
        """Deleted, not hidden: nothing left to leak or to switch back on."""
        await client.put(f"{TRIPS}/{trip['id']}/location", json=LISBON, headers=auth_headers)

        stopped = await client.delete(f"{TRIPS}/{trip['id']}/location", headers=auth_headers)
        assert stopped.status_code == 204
        assert await db.scalar(select(MemberLocation)) is None

    async def test_stopping_twice_is_harmless(
        self, client: AsyncClient, trip: dict, auth_headers: dict
    ):
        await client.delete(f"{TRIPS}/{trip['id']}/location", headers=auth_headers)
        response = await client.delete(f"{TRIPS}/{trip['id']}/location", headers=auth_headers)
        assert response.status_code == 204

    async def test_members_see_each_other(
        self,
        client: AsyncClient,
        trip: dict,
        invite_code: str,
        auth_headers: dict,
        other_headers: dict,
    ):
        await client.post(f"{TRIPS}/join", json={"code": invite_code}, headers=other_headers)
        await client.put(f"{TRIPS}/{trip['id']}/location", json=LISBON, headers=auth_headers)
        await client.put(f"{TRIPS}/{trip['id']}/location", json=PORTO, headers=other_headers)

        response = await client.get(f"{TRIPS}/{trip['id']}/locations", headers=other_headers)
        assert len(response.json()) == 2

    async def test_impossible_coordinates_are_rejected(
        self, client: AsyncClient, trip: dict, auth_headers: dict
    ):
        for payload in (
            {"latitude": 91, "longitude": 0},
            {"latitude": -91, "longitude": 0},
            {"latitude": 0, "longitude": 181},
            {"latitude": 0, "longitude": -181},
        ):
            response = await client.put(
                f"{TRIPS}/{trip['id']}/location", json=payload, headers=auth_headers
            )
            assert response.status_code == 422


class TestPins:
    async def test_creates_and_lists(self, client: AsyncClient, trip: dict, auth_headers: dict):
        created = await client.post(
            f"{TRIPS}/{trip['id']}/pins",
            json={"name": "Ostello", "category": "lodging", **PORTO},
            headers=auth_headers,
        )
        assert created.status_code == 201
        assert created.json()["category"] == "lodging"

        listed = await client.get(f"{TRIPS}/{trip['id']}/pins", headers=auth_headers)
        assert [p["name"] for p in listed.json()] == ["Ostello"]

    async def test_category_defaults_to_other(
        self, client: AsyncClient, trip: dict, auth_headers: dict
    ):
        response = await client.post(
            f"{TRIPS}/{trip['id']}/pins", json={"name": "Boh", **PORTO}, headers=auth_headers
        )
        assert response.json()["category"] == "other"

    async def test_unknown_category_is_rejected(
        self, client: AsyncClient, trip: dict, auth_headers: dict
    ):
        response = await client.post(
            f"{TRIPS}/{trip['id']}/pins",
            json={"name": "X", "category": "nightclub", **PORTO},
            headers=auth_headers,
        )
        assert response.status_code == 422

    async def test_patches_a_field(self, client: AsyncClient, trip: dict, auth_headers: dict):
        created = await client.post(
            f"{TRIPS}/{trip['id']}/pins",
            json={"name": "Vecchio", "description": "Da tenere", **PORTO},
            headers=auth_headers,
        )
        response = await client.patch(
            f"{TRIPS}/{trip['id']}/pins/{created.json()['id']}",
            json={"name": "Nuovo"},
            headers=auth_headers,
        )
        assert response.json()["name"] == "Nuovo"
        # exclude_unset: a PATCH must not blank what it did not mention.
        assert response.json()["description"] == "Da tenere"

    async def test_deletes(self, client: AsyncClient, trip: dict, auth_headers: dict):
        created = await client.post(
            f"{TRIPS}/{trip['id']}/pins", json={"name": "X", **PORTO}, headers=auth_headers
        )
        deleted = await client.delete(
            f"{TRIPS}/{trip['id']}/pins/{created.json()['id']}", headers=auth_headers
        )
        assert deleted.status_code == 204
        assert (await client.get(f"{TRIPS}/{trip['id']}/pins", headers=auth_headers)).json() == []

    async def test_any_member_can_delete(
        self,
        client: AsyncClient,
        trip: dict,
        invite_code: str,
        auth_headers: dict,
        other_headers: dict,
    ):
        """Same rule as expenses and tasks: a shared map has to be tidyable."""
        await client.post(f"{TRIPS}/join", json={"code": invite_code}, headers=other_headers)
        created = await client.post(
            f"{TRIPS}/{trip['id']}/pins", json={"name": "X", **PORTO}, headers=auth_headers
        )
        response = await client.delete(
            f"{TRIPS}/{trip['id']}/pins/{created.json()['id']}", headers=other_headers
        )
        assert response.status_code == 204

    async def test_unknown_pin_is_404(self, client: AsyncClient, trip: dict, auth_headers: dict):
        response = await client.patch(
            f"{TRIPS}/{trip['id']}/pins/{uuid4()}", json={"name": "X"}, headers=auth_headers
        )
        assert response.status_code == 404

    async def test_impossible_coordinates_are_rejected(
        self, client: AsyncClient, trip: dict, auth_headers: dict
    ):
        response = await client.post(
            f"{TRIPS}/{trip['id']}/pins",
            json={"name": "Nel nulla", "latitude": 200, "longitude": 0},
            headers=auth_headers,
        )
        assert response.status_code == 422


class TestIsolation:
    async def test_outsider_cannot_read_locations(
        self, client: AsyncClient, trip: dict, other_headers: dict
    ):
        response = await client.get(f"{TRIPS}/{trip['id']}/locations", headers=other_headers)
        assert response.status_code == 404

    async def test_outsider_cannot_share_a_location(
        self, client: AsyncClient, trip: dict, other_headers: dict
    ):
        response = await client.put(
            f"{TRIPS}/{trip['id']}/location", json=LISBON, headers=other_headers
        )
        assert response.status_code == 404

    async def test_outsider_cannot_read_pins(
        self, client: AsyncClient, trip: dict, other_headers: dict
    ):
        response = await client.get(f"{TRIPS}/{trip['id']}/pins", headers=other_headers)
        assert response.status_code == 404

    async def test_a_pin_id_does_not_cross_trips(
        self, client: AsyncClient, trip: dict, auth_headers: dict, other_headers: dict
    ):
        created = await client.post(
            f"{TRIPS}/{trip['id']}/pins", json={"name": "Segreto", **PORTO}, headers=auth_headers
        )
        theirs = await client.post(TRIPS, json={"name": "Altro"}, headers=other_headers)

        response = await client.delete(
            f"{TRIPS}/{theirs.json()['id']}/pins/{created.json()['id']}", headers=other_headers
        )
        assert response.status_code == 404

    async def test_leaving_the_trip_takes_the_location(
        self,
        client: AsyncClient,
        trip: dict,
        invite_code: str,
        auth_headers: dict,
        other_headers: dict,
        db: AsyncSession,
    ):
        """Otherwise they sit on the group's map for up to half an hour after
        losing access to it."""
        await client.post(f"{TRIPS}/join", json={"code": invite_code}, headers=other_headers)
        await client.put(f"{TRIPS}/{trip['id']}/location", json=PORTO, headers=other_headers)

        await client.delete(f"{TRIPS}/{trip['id']}/members/me", headers=other_headers)

        remaining = await client.get(f"{TRIPS}/{trip['id']}/locations", headers=auth_headers)
        assert remaining.json() == []
        assert await db.scalar(select(MemberLocation)) is None

    async def test_removal_takes_the_location_too(
        self,
        client: AsyncClient,
        trip: dict,
        invite_code: str,
        auth_headers: dict,
        other_headers: dict,
        db: AsyncSession,
    ):
        await client.post(f"{TRIPS}/join", json={"code": invite_code}, headers=other_headers)
        await client.put(f"{TRIPS}/{trip['id']}/location", json=PORTO, headers=other_headers)
        member = await client.get("/api/v1/auth/me", headers=other_headers)

        await client.delete(
            f"{TRIPS}/{trip['id']}/members/{member.json()['id']}", headers=auth_headers
        )
        assert await db.scalar(select(MemberLocation)) is None
