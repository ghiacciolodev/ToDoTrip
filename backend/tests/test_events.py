"""Realtime channel tests.

Starlette's TestClient drives both sides of the loop — mutate over HTTP, hear
about it over the websocket — so the whole feature runs in CI with no server.
"""

import time
from unittest.mock import patch

import pytest
from starlette.testclient import TestClient
from starlette.websockets import WebSocketDisconnect

from app.core import events, security
from app.database import get_db
from app.main import app
from app.routers import events as events_router
from tests.conftest import SECOND_USER, USER, TestSession

TRIPS = "/api/v1/trips"


@pytest.fixture
def tc():
    """A synchronous client wired to the test database.

    The async `client` fixture cannot speak websockets; this one speaks both,
    so a test can post an expense and listen on the socket in the same breath.
    """

    async def _override_get_db():
        async with TestSession() as session:
            yield session

    app.dependency_overrides[get_db] = _override_get_db
    with TestClient(app) as tc:
        yield tc
    app.dependency_overrides.clear()


def _login(tc: TestClient, user: dict) -> tuple[str, str, dict]:
    """Register + login. Returns (user_id, access_token, auth headers)."""
    tc.post("/api/v1/auth/register", json=user)
    response = tc.post(
        "/api/v1/auth/login", json={"email": user["email"], "password": user["password"]}
    )
    token = response.json()["access_token"]
    headers = {"Authorization": f"Bearer {token}"}
    user_id = tc.get("/api/v1/auth/me", headers=headers).json()["id"]
    return user_id, token, headers


@pytest.fixture
def group(tc: TestClient) -> dict:
    """Mario owns a trip, Luca is a member. Ids, tokens and headers for both."""
    mario_id, mario_token, mario_headers = _login(tc, USER)
    luca_id, luca_token, luca_headers = _login(tc, SECOND_USER)

    trip = tc.post(TRIPS, json={"name": "Lisbona 2026"}, headers=mario_headers).json()
    code = tc.post(f"{TRIPS}/{trip['id']}/invites", json={}, headers=mario_headers).json()["code"]
    tc.post(f"{TRIPS}/join", json={"code": code}, headers=luca_headers)

    return {
        "trip_id": trip["id"],
        "url": f"{TRIPS}/{trip['id']}/events",
        "mario": mario_id,
        "mario_token": mario_token,
        "mario_headers": mario_headers,
        "luca": luca_id,
        "luca_token": luca_token,
        "luca_headers": luca_headers,
    }


def _expense(tc: TestClient, g: dict, headers: dict, payer: str) -> None:
    response = tc.post(
        f"{TRIPS}/{g['trip_id']}/expenses",
        json={
            "description": "Cena",
            "amount_cents": 3000,
            "paid_by": payer,
            "participants": [g["mario"], g["luca"]],
        },
        headers=headers,
    )
    assert response.status_code == 201


class TestAuth:
    def test_garbage_token_is_rejected_with_4401(self, tc: TestClient, group: dict):
        with tc.websocket_connect(group["url"]) as ws:
            ws.send_json({"token": "garbage"})
            with pytest.raises(WebSocketDisconnect) as excinfo:
                ws.receive_json()
        assert excinfo.value.code == 4401

    def test_a_non_member_is_rejected_with_4403(self, tc: TestClient, group: dict):
        """Valid identity, wrong trip: same 403-shaped answer as the REST API."""
        _, outsider_token, _ = _login(
            tc, {"email": "anna@test.it", "password": "password123", "display_name": "Anna"}
        )
        with tc.websocket_connect(group["url"]) as ws:
            ws.send_json({"token": outsider_token})
            with pytest.raises(WebSocketDisconnect) as excinfo:
                ws.receive_json()
        assert excinfo.value.code == 4403

    def test_a_member_is_acknowledged(self, tc: TestClient, group: dict):
        with tc.websocket_connect(group["url"]) as ws:
            ws.send_json({"token": group["luca_token"]})
            assert ws.receive_json() == {"type": "connected"}


class TestBroadcast:
    def test_a_member_hears_someone_elses_change(self, tc: TestClient, group: dict):
        with tc.websocket_connect(group["url"]) as luca_ws:
            luca_ws.send_json({"token": group["luca_token"]})
            assert luca_ws.receive_json()["type"] == "connected"

            _expense(tc, group, group["mario_headers"], payer=group["mario"])

            event = luca_ws.receive_json()
            assert event == {
                "type": "expenses.changed",
                "trip_id": group["trip_id"],
                "actor_id": group["mario"],
            }

    def test_the_actor_does_not_hear_their_own_change(self, tc: TestClient, group: dict):
        """That client already invalidated locally; an echo only causes flicker.

        Proven by ordering: Mario acts, then Luca acts, and the first thing
        Mario ever receives is Luca's event — his own never arrived.
        """
        with (
            tc.websocket_connect(group["url"]) as mario_ws,
            tc.websocket_connect(group["url"]) as luca_ws,
        ):
            mario_ws.send_json({"token": group["mario_token"]})
            assert mario_ws.receive_json()["type"] == "connected"
            luca_ws.send_json({"token": group["luca_token"]})
            assert luca_ws.receive_json()["type"] == "connected"

            _expense(tc, group, group["mario_headers"], payer=group["mario"])
            # Luca hearing it proves the event went through the manager.
            assert luca_ws.receive_json()["type"] == "expenses.changed"

            tc.post(
                f"{TRIPS}/{group['trip_id']}/items",
                json={"type": "task", "title": "Comprare il ghiaccio"},
                headers=group["luca_headers"],
            )

            first_for_mario = mario_ws.receive_json()
            assert first_for_mario["type"] == "items.changed"
            assert first_for_mario["actor_id"] == group["luca"]

    def test_disconnecting_removes_the_socket(self, tc: TestClient, group: dict):
        trip_id = _uuid(group["trip_id"])
        with tc.websocket_connect(group["url"]) as ws:
            ws.send_json({"token": group["luca_token"]})
            assert ws.receive_json()["type"] == "connected"
            assert events.connection_count(trip_id) == 1

        # The server notices the close on its own schedule, hence the wait.
        for _ in range(40):
            if events.connection_count(trip_id) == 0:
                break
            time.sleep(0.05)
        assert events.connection_count(trip_id) == 0


class TestLocationPush:
    """Positions are the one thing pushed with their data, not announced.

    Two floats changing every twenty seconds: telling four moving clients to
    each re-run a GET would be dozens of requests a minute to move sixty bytes.
    """

    def test_a_position_arrives_with_its_coordinates(self, tc: TestClient, group: dict):
        with tc.websocket_connect(group["url"]) as luca_ws:
            luca_ws.send_json({"token": group["luca_token"]})
            assert luca_ws.receive_json()["type"] == "connected"

            tc.put(
                f"{TRIPS}/{group['trip_id']}/location",
                json={"latitude": 38.7223, "longitude": -9.1393, "accuracy_m": 12.5},
                headers=group["mario_headers"],
            )

            event = luca_ws.receive_json()
            assert event["type"] == "location.update"
            assert event["user_id"] == group["mario"]
            assert event["lat"] == 38.7223
            assert event["lng"] == -9.1393
            assert event["at"]

    def test_the_mover_does_not_hear_themselves(self, tc: TestClient, group: dict):
        with (
            tc.websocket_connect(group["url"]) as mario_ws,
            tc.websocket_connect(group["url"]) as luca_ws,
        ):
            mario_ws.send_json({"token": group["mario_token"]})
            assert mario_ws.receive_json()["type"] == "connected"
            luca_ws.send_json({"token": group["luca_token"]})
            assert luca_ws.receive_json()["type"] == "connected"

            tc.put(
                f"{TRIPS}/{group['trip_id']}/location",
                json={"latitude": 38.7223, "longitude": -9.1393},
                headers=group["mario_headers"],
            )
            assert luca_ws.receive_json()["type"] == "location.update"

            tc.put(
                f"{TRIPS}/{group['trip_id']}/location",
                json={"latitude": 41.1579, "longitude": -8.6291},
                headers=group["luca_headers"],
            )
            # Mario's first message is Luca's move: his own never came back.
            first_for_mario = mario_ws.receive_json()
            assert first_for_mario["user_id"] == group["luca"]

    def test_stopping_is_announced(self, tc: TestClient, group: dict):
        with tc.websocket_connect(group["url"]) as luca_ws:
            luca_ws.send_json({"token": group["luca_token"]})
            assert luca_ws.receive_json()["type"] == "connected"

            tc.delete(f"{TRIPS}/{group['trip_id']}/location", headers=group["mario_headers"])

            event = luca_ws.receive_json()
            assert event["type"] == "location.cleared"
            assert event["user_id"] == group["mario"]

    def test_pins_are_announced_without_their_data(self, tc: TestClient, group: dict):
        """Durable, structured state stays behind a GET."""
        with tc.websocket_connect(group["url"]) as luca_ws:
            luca_ws.send_json({"token": group["luca_token"]})
            assert luca_ws.receive_json()["type"] == "connected"

            tc.post(
                f"{TRIPS}/{group['trip_id']}/pins",
                json={"name": "Ostello", "latitude": 41.1579, "longitude": -8.6291},
                headers=group["mario_headers"],
            )

            event = luca_ws.receive_json()
            assert event["type"] == "pins.changed"
            assert set(event) == {"type", "trip_id", "actor_id"}


class TestAccessRevocation:
    def test_a_removed_member_is_cut_off(self, tc: TestClient, group: dict):
        """No data travels here, but even the bell is a signal of the group's
        activity, and a removed member is not entitled to it."""
        with tc.websocket_connect(group["url"]) as luca_ws:
            luca_ws.send_json({"token": group["luca_token"]})
            assert luca_ws.receive_json()["type"] == "connected"

            response = tc.delete(
                f"{TRIPS}/{group['trip_id']}/members/{group['luca']}",
                headers=group["mario_headers"],
            )
            assert response.status_code == 204

            # The change is announced first, then the line goes dead.
            assert luca_ws.receive_json()["type"] == "members.changed"
            with pytest.raises(WebSocketDisconnect) as excinfo:
                luca_ws.receive_json()
            assert excinfo.value.code == 4403

    def test_a_deleted_trip_hangs_up_after_the_news(self, tc: TestClient, group: dict):
        with tc.websocket_connect(group["url"]) as luca_ws:
            luca_ws.send_json({"token": group["luca_token"]})
            assert luca_ws.receive_json()["type"] == "connected"

            tc.delete(f"{TRIPS}/{group['trip_id']}", headers=group["mario_headers"])

            assert luca_ws.receive_json()["type"] == "trip.deleted"
            with pytest.raises(WebSocketDisconnect):
                luca_ws.receive_json()


def _uuid(value: str):
    from uuid import UUID

    return UUID(value)


class TestSessionStaysAuthorised:
    """Authorising once at connect was the hole.

    A websocket lives for as long as the screen is open; the token that opened
    it is good for fifteen minutes. Without a recheck, the socket outlives its
    own authorisation.
    """

    def test_an_expired_token_closes_the_socket(self, tc: TestClient, group: dict):
        real_decode = security.decode_access_token
        seen = {"count": 0}

        def valid_once(token: str):
            """Valid for the handshake, expired by the first recheck.

            Driven by a counter rather than by a real clock: a test that waits
            for a token to age out is a test that fails on a slow machine.
            """
            seen["count"] += 1
            return real_decode(token) if seen["count"] == 1 else None

        with (
            patch.object(events_router, "_REVALIDATE_SECONDS", 0.05),
            patch.object(events_router.security, "decode_access_token", valid_once),
            tc.websocket_connect(group["url"]) as luca_ws,
        ):
            luca_ws.send_json({"token": group["luca_token"]})
            assert luca_ws.receive_json()["type"] == "connected"

            with pytest.raises(WebSocketDisconnect) as excinfo:
                luca_ws.receive_json()
            assert excinfo.value.code == 4401

    def test_a_deactivated_account_is_cut_off(self, tc: TestClient, group: dict):
        """Deleting an account does not go through the trip's event fan-out, so
        only the recheck notices."""
        with (
            patch.object(events_router, "_REVALIDATE_SECONDS", 0.05),
            patch.object(events_router, "SessionLocal", TestSession),
            tc.websocket_connect(group["url"]) as luca_ws,
        ):
            luca_ws.send_json({"token": group["luca_token"]})
            assert luca_ws.receive_json()["type"] == "connected"

            tc.delete("/api/v1/auth/me", headers=group["luca_headers"])

            with pytest.raises(WebSocketDisconnect) as excinfo:
                luca_ws.receive_json()
            assert excinfo.value.code == 4401

    def test_a_still_valid_session_survives_the_rechecks(self, tc: TestClient, group: dict):
        """The recheck must not become a periodic disconnection."""
        with (
            patch.object(events_router, "_REVALIDATE_SECONDS", 0.05),
            patch.object(events_router, "SessionLocal", TestSession),
            tc.websocket_connect(group["url"]) as luca_ws,
        ):
            luca_ws.send_json({"token": group["luca_token"]})
            assert luca_ws.receive_json()["type"] == "connected"

            # Several passes go by, then something real happens: the socket
            # is expected to still be there to hear it.
            time.sleep(0.3)
            _expense(tc, group, group["mario_headers"], group["mario"])

            assert luca_ws.receive_json()["type"] == "expenses.changed"
