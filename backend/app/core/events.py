"""Realtime fan-out: the fact that something changed, never the data.

A client hearing {"type": "expenses.changed"} re-runs the GET it already knows;
the database stays the only source of truth and this channel is just a bell.
That removes the entire category of sync problems — no merging, no conflicts,
no client drifting from the server — at the cost of one extra HTTP request per
event, and events are rare.

Everything here is in-memory and single-process on purpose: one worker is the
deployment target. With several workers an event raised on worker 1 never
reaches sockets held by worker 3, and realtime that works intermittently is
worse than none (see README). The step after that is Redis pub/sub, behind the
same emit() facade.
"""

import asyncio
import contextlib
import logging
from dataclasses import dataclass, field
from uuid import UUID

from fastapi import WebSocket
from sqlalchemy.ext.asyncio import AsyncSession

from app.models import NotificationKind
from app.services import notification_service

_log = logging.getLogger(__name__)


@dataclass(frozen=True, slots=True)
class Notify:
    """The durable half of an event: what to write down for whoever missed it.

    Passed to [emit] alongside the websocket announcement, because they are the
    same moment described twice — "X happened in trip Y, caused by Z". Writing
    notifications in the routers instead would mean revisiting all ten of them
    the day push notifications arrive.
    """

    kind: NotificationKind

    # Frozen facts, never a rendered sentence: the client owns the wording.
    payload: dict = field(default_factory=dict)

    entity_id: UUID | None = None

    # Narrows the recipients from "every member but the actor" to a few — a
    # repayment concerns the person who was paid, an assignment the assignees.
    only: list[UUID] | None = None


class _ConnectionManager:
    """Open sockets per trip, with the user behind each one.

    The user id is kept so a broadcast can skip the actor's own sockets, and so
    a member who loses access can be cut off by id.
    """

    def __init__(self) -> None:
        self._sockets: dict[UUID, dict[WebSocket, UUID]] = {}
        self._lock = asyncio.Lock()

    async def add(self, trip_id: UUID, socket: WebSocket, user_id: UUID) -> None:
        async with self._lock:
            self._sockets.setdefault(trip_id, {})[socket] = user_id

    async def remove(self, trip_id: UUID, socket: WebSocket) -> None:
        async with self._lock:
            connections = self._sockets.get(trip_id)
            if connections is not None:
                connections.pop(socket, None)
                if not connections:
                    del self._sockets[trip_id]

    async def snapshot(self, trip_id: UUID) -> list[tuple[WebSocket, UUID]]:
        """Copied under the lock, sent outside it: a slow client must not block
        registrations, and the dict must not change mid-iteration."""
        async with self._lock:
            return list(self._sockets.get(trip_id, {}).items())


_manager = _ConnectionManager()


def connection_count(trip_id: UUID) -> int:
    """How many sockets a trip currently holds. Exists for the tests."""
    return len(_manager._sockets.get(trip_id, {}))


async def register(trip_id: UUID, socket: WebSocket, user_id: UUID) -> None:
    await _manager.add(trip_id, socket, user_id)


async def unregister(trip_id: UUID, socket: WebSocket) -> None:
    await _manager.remove(trip_id, socket)


async def emit(
    trip_id: UUID,
    type_: str,
    *,
    actor_id: UUID,
    data: dict | None = None,
    db: AsyncSession | None = None,
    notify: Notify | None = None,
) -> None:
    """The single door every mutation announces itself through.

    Routers call this and nothing else. It feeds two channels from one call —
    the websocket bell for whoever is looking, and the notification feed for
    whoever is not — and push notifications will be a third, added here rather
    than across ten endpoints.

    Must be called after the commit: announcing a change that then rolls back
    sends every client fetching data that does not exist.

    The actor's own sockets are skipped — that client already invalidated
    locally, and a second refresh only makes the UI flicker.

    [data] is the deliberate exception to "announce the fact, never the data".
    A position is two floats that change every twenty seconds: telling four
    moving clients to each re-run a GET would be dozens of requests a minute to
    move sixty bytes. Durable, structured state stays behind a GET; ephemeral,
    tiny and frequent state travels here.

    [notify] is the opposite exception: a websocket event missed is harmless,
    because the next fetch shows current data anyway, while a notification
    missed never happened at all. Only a few events deserve one.
    """
    payload = {
        "type": type_,
        "trip_id": str(trip_id),
        "actor_id": str(actor_id),
        **(data or {}),
    }
    for socket, user_id in await _manager.snapshot(trip_id):
        if user_id == actor_id:
            continue
        await _send(trip_id, socket, payload)

    if notify is None or db is None:
        return
    try:
        await notification_service.record(
            db,
            trip_id=trip_id,
            actor_id=actor_id,
            kind=notify.kind,
            payload=notify.payload,
            entity_id=notify.entity_id,
            only=notify.only,
        )
    except Exception:  # noqa: BLE001
        # The expense is already saved and the caller is owed its 201. A feed
        # row that failed to write is worth a log line, never a failed request
        # for work that actually succeeded.
        _log.exception("could not record notifications for %s on %s", type_, trip_id)
        await db.rollback()


async def kick(trip_id: UUID, user_id: UUID) -> None:
    """Close every socket a user holds on this trip.

    Called when they are removed or leave: without it a former member keeps
    hearing the bell — no data, but still a signal of the group's activity they
    are no longer entitled to.
    """
    for socket, owner in await _manager.snapshot(trip_id):
        if owner == user_id:
            await _close(trip_id, socket, code=4403)


async def close_trip(trip_id: UUID) -> None:
    """The trip is gone; so is everything listening to it."""
    for socket, _ in await _manager.snapshot(trip_id):
        await _close(trip_id, socket, code=1000)


async def _send(trip_id: UUID, socket: WebSocket, payload: dict) -> None:
    try:
        await socket.send_json(payload)
    except Exception:  # noqa: BLE001 — a dead socket must never fail the request
        await _manager.remove(trip_id, socket)


async def _close(trip_id: UUID, socket: WebSocket, *, code: int) -> None:
    await _manager.remove(trip_id, socket)
    # Already closed is fine: the goal is reached either way.
    with contextlib.suppress(Exception):
        await socket.close(code=code)
