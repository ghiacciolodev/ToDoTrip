"""The realtime channel: one websocket per open trip screen.

Clients connect when the trip screen mounts and disconnect when it unmounts,
so the server never has to know which trips a user is "subscribed" to.
"""

import asyncio
import contextlib
from uuid import UUID

from fastapi import APIRouter, WebSocket, WebSocketDisconnect

from app.core import events, security
from app.dependencies import DbSession
from app.models import User
from app.services import trip_service
from app.services.trip_service import NotAMember

router = APIRouter(prefix="/trips/{trip_id}/events", tags=["events"])

# Long enough for a slow handshake, short enough that an unauthenticated socket
# cannot squat a connection slot.
_AUTH_TIMEOUT_SECONDS = 10

# Application close codes, mirroring the HTTP statuses the REST API would give.
_WS_UNAUTHENTICATED = 4401
_WS_NOT_A_MEMBER = 4403


@router.websocket("")
async def trip_events(websocket: WebSocket, trip_id: UUID, db: DbSession):
    """Authenticate, then hold the socket open until the client goes away.

    The token travels in the first message, never in the query string: URLs end
    up in server and proxy logs, tokens must not.
    """
    await websocket.accept()

    try:
        message = await asyncio.wait_for(websocket.receive_json(), timeout=_AUTH_TIMEOUT_SECONDS)
    except (TimeoutError, ValueError, WebSocketDisconnect, RuntimeError):
        # No message, junk instead of JSON, or an already-gone client: the
        # outcome is the same, no identity was presented.
        await _reject(websocket, _WS_UNAUTHENTICATED)
        return

    token = message.get("token", "") if isinstance(message, dict) else ""
    user_id = security.decode_access_token(str(token))
    if user_id is None:
        await _reject(websocket, _WS_UNAUTHENTICATED)
        return

    user = await db.get(User, user_id)
    if user is None or not user.is_active:
        await _reject(websocket, _WS_UNAUTHENTICATED)
        return

    try:
        await trip_service.get_membership(db, trip_id, user_id)
    except NotAMember:
        await _reject(websocket, _WS_NOT_A_MEMBER)
        return

    # The session has served its purpose. A websocket lives for minutes and
    # must not hold a pooled database connection for all of them.
    await db.close()

    await events.register(trip_id, websocket, user_id)
    # Explicit ack: the client knows it is live, and a reconnection can tell
    # "back online, refetch everything" apart from the first connect.
    await websocket.send_json({"type": "connected"})

    try:
        # The client has nothing meaningful to say; this loop exists to notice
        # the disconnect. Protocol-level ping/pong is handled by the server.
        while True:
            await websocket.receive_text()
    except WebSocketDisconnect:
        pass
    finally:
        await events.unregister(trip_id, websocket)


async def _reject(websocket: WebSocket, code: int) -> None:
    # RuntimeError: the client hung up first; there is nothing left to close.
    with contextlib.suppress(RuntimeError):
        await websocket.close(code=code)
