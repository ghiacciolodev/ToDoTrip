"""Writing, reading and forgetting the notification feed."""

from base64 import urlsafe_b64decode, urlsafe_b64encode
from datetime import UTC, datetime, timedelta
from uuid import UUID

from sqlalchemy import delete, func, or_, select, tuple_, update
from sqlalchemy.ext.asyncio import AsyncSession

from app.models import Notification, NotificationKind, TripMember

# How long a notification is worth keeping. Read ones go sooner: they have
# already done their job, and the feed is a reminder list, not an archive.
_KEEP_READ = timedelta(days=30)
_KEEP_UNREAD = timedelta(days=90)

# The most a single page can ask for, so a client cannot pull the whole history
# in one request by passing limit=100000.
MAX_PAGE = 50


async def recipients_for(
    db: AsyncSession,
    trip_id: UUID,
    actor_id: UUID,
    *,
    only: list[UUID] | None = None,
) -> list[UUID]:
    """Who hears about it: members of the trip, minus the actor, minus the muted.

    Never the person who did it — being told about your own action is the
    fastest way to teach someone that the bell means nothing.

    `only` narrows it to a specific few, still subject to the same three rules:
    a repayment concerns the person who received it, an assignment concerns the
    people assigned.
    """
    query = select(TripMember.user_id).where(
        TripMember.trip_id == trip_id,
        TripMember.user_id != actor_id,
        # The switch in trip settings, doing what it says.
        TripMember.muted.is_(False),
    )
    if only is not None:
        if not only:
            return []
        query = query.where(TripMember.user_id.in_(only))
    return list((await db.execute(query)).scalars().all())


async def record(
    db: AsyncSession,
    *,
    trip_id: UUID,
    actor_id: UUID,
    kind: NotificationKind,
    payload: dict,
    entity_id: UUID | None = None,
    only: list[UUID] | None = None,
) -> int:
    """Write one row per recipient. Returns how many were written."""
    targets = await recipients_for(db, trip_id, actor_id, only=only)
    if not targets:
        return 0

    db.add_all(
        [
            Notification(
                user_id=user_id,
                trip_id=trip_id,
                kind=kind,
                actor_id=actor_id,
                entity_id=entity_id,
                payload=payload,
            )
            for user_id in targets
        ]
    )
    await db.commit()
    return len(targets)


def _encode(row: Notification) -> str:
    """An opaque cursor. The client passes it back and never reads it."""
    raw = f"{row.created_at.isoformat()}|{row.id}"
    return urlsafe_b64encode(raw.encode()).decode()


def _decode(cursor: str) -> tuple[datetime, UUID] | None:
    try:
        at, row_id = urlsafe_b64decode(cursor.encode()).decode().split("|", 1)
        return datetime.fromisoformat(at), UUID(row_id)
    except (ValueError, TypeError):
        # A cursor that does not parse is treated as no cursor: a corrupted
        # query string should hand back the first page, not a 500.
        return None


async def feed(
    db: AsyncSession,
    user_id: UUID,
    *,
    limit: int = 30,
    before: str | None = None,
) -> tuple[list[Notification], str | None]:
    """One page of somebody's notifications, newest first, plus the next cursor.

    Keyset pagination on (created_at, id) rather than an offset. With an offset,
    a notification arriving while the reader is scrolling shifts everything down
    by one, and page two opens with a row they have already read.
    """
    limit = max(1, min(limit, MAX_PAGE))

    query = (
        select(Notification)
        .where(Notification.user_id == user_id)
        .order_by(Notification.created_at.desc(), Notification.id.desc())
        # One more than asked for: whether a next page exists is answered by
        # whether that extra row came back, with no second count query.
        .limit(limit + 1)
    )

    if before is not None and (cursor := _decode(before)) is not None:
        query = query.where(tuple_(Notification.created_at, Notification.id) < tuple_(*cursor))

    rows = list((await db.execute(query)).scalars().all())
    if len(rows) > limit:
        return rows[:limit], _encode(rows[limit - 1])
    return rows, None


async def unread_count(db: AsyncSession, user_id: UUID) -> int:
    """The badge. Its own query, and its own endpoint: it runs on every cold
    start and every return to the foreground, and fetching thirty full
    notifications to render one number would be most of that traffic."""
    return await db.scalar(
        select(func.count())
        .select_from(Notification)
        .where(Notification.user_id == user_id, Notification.read_at.is_(None))
    )


async def mark_read(db: AsyncSession, user_id: UUID, ids: list[UUID]) -> None:
    """Mark specific rows read. Scoped to the caller, so an id belonging to
    somebody else changes nothing rather than raising."""
    if not ids:
        return
    await db.execute(
        update(Notification)
        .where(
            Notification.user_id == user_id,
            Notification.id.in_(ids),
            Notification.read_at.is_(None),
        )
        .values(read_at=datetime.now(UTC))
    )
    await db.commit()


async def mark_all_read(db: AsyncSession, user_id: UUID) -> None:
    await db.execute(
        update(Notification)
        .where(Notification.user_id == user_id, Notification.read_at.is_(None))
        .values(read_at=datetime.now(UTC))
    )
    await db.commit()


async def remove(db: AsyncSession, user_id: UUID, notification_id: UUID) -> bool:
    """Delete one of the caller's own notifications. True when there was one.

    Scoped to the caller like every other write here, so an id belonging to
    somebody else deletes nothing rather than raising — there is no way to probe
    another person's feed one id at a time.
    """
    result = await db.execute(
        delete(Notification).where(
            Notification.user_id == user_id, Notification.id == notification_id
        )
    )
    await db.commit()
    return bool(result.rowcount)


async def clear(db: AsyncSession, user_id: UUID) -> int:
    """Empty the caller's feed. Returns how many rows went."""
    result = await db.execute(delete(Notification).where(Notification.user_id == user_id))
    await db.commit()
    return result.rowcount or 0


async def purge(db: AsyncSession) -> int:
    """Drop notifications nobody will read again. Returns how many went.

    Called at startup rather than from a scheduler: this is one DELETE on an
    indexed column, and adding a cron container to run it would be more moving
    parts than the problem deserves at this size.
    """
    now = datetime.now(UTC)
    result = await db.execute(
        delete(Notification).where(
            or_(
                Notification.read_at.is_not(None) & (Notification.created_at < now - _KEEP_READ),
                Notification.read_at.is_(None) & (Notification.created_at < now - _KEEP_UNREAD),
            )
        )
    )
    await db.commit()
    return result.rowcount or 0
