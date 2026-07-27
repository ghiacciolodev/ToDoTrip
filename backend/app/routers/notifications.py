"""HTTP layer for the notification feed.

Not scoped to a trip: the feed crosses all of them, which is the point — one
place to find out what happened while the phone was in a pocket.
"""

from typing import Annotated
from uuid import UUID

from fastapi import APIRouter, Query, status

from app.dependencies import CurrentUser, DbSession
from app.schemas.notification import (
    MarkRead,
    NotificationFeed,
    NotificationPublic,
    UnreadCount,
)
from app.services import notification_service

router = APIRouter(prefix="/notifications", tags=["notifications"])


@router.get("", response_model=NotificationFeed)
async def list_notifications(
    db: DbSession,
    user: CurrentUser,
    limit: Annotated[int, Query(ge=1, le=notification_service.MAX_PAGE)] = 30,
    before: str | None = None,
):
    """One page of the caller's own notifications, newest first."""
    items, cursor = await notification_service.feed(db, user.id, limit=limit, before=before)
    return NotificationFeed(
        items=[NotificationPublic.model_validate(row) for row in items],
        next_cursor=cursor,
    )


# Declared before "/{...}" would ever be reached, and kept apart from the feed
# on purpose: the badge is asked for on every cold start and every return to the
# foreground, and fetching thirty full rows to render one number would be most
# of the app's traffic.
@router.get("/unread-count", response_model=UnreadCount)
async def unread_count(db: DbSession, user: CurrentUser):
    return UnreadCount(count=await notification_service.unread_count(db, user.id))


@router.post("/read", status_code=status.HTTP_204_NO_CONTENT)
async def mark_read(payload: MarkRead, db: DbSession, user: CurrentUser):
    """Mark specific notifications read.

    Ids belonging to somebody else simply do nothing: the update is scoped to
    the caller, so there is no way to read — or to probe for — another person's
    feed one id at a time.
    """
    await notification_service.mark_read(db, user.id, payload.ids)


@router.post("/read-all", status_code=status.HTTP_204_NO_CONTENT)
async def mark_all_read(db: DbSession, user: CurrentUser):
    await notification_service.mark_all_read(db, user.id)


@router.delete("", status_code=status.HTTP_204_NO_CONTENT)
async def clear(db: DbSession, user: CurrentUser):
    """Empty the whole feed. Only ever the caller's own rows."""
    await notification_service.clear(db, user.id)


@router.delete("/{notification_id}", status_code=status.HTTP_204_NO_CONTENT)
async def remove(notification_id: UUID, db: DbSession, user: CurrentUser):
    """Delete one notification.

    Idempotent, and silent about ids that are not the caller's: answering 404
    for somebody else's id would confirm that it exists.
    """
    await notification_service.remove(db, user.id, notification_id)
