"""Calendar and task use cases, all scoped to a single trip."""

from datetime import UTC, datetime
from uuid import UUID

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models import Item, ItemAssignee, ItemType, TripMember


class ItemNotFound(Exception):
    """No such item inside this trip."""


class AssigneeNotMember(Exception):
    """Cannot assign work to someone outside the group."""


class NotATask(Exception):
    """Completion only applies to tasks, not to calendar events."""


async def _ensure_members(db: AsyncSession, trip_id: UUID, user_ids: list[UUID]) -> None:
    """Reject any assignee who is not in the trip.

    Resolved in one query rather than one per person: work cannot be handed to
    someone outside the group.
    """
    if not user_ids:
        return
    result = await db.execute(
        select(TripMember.user_id).where(
            TripMember.trip_id == trip_id, TripMember.user_id.in_(user_ids)
        )
    )
    if set(result.scalars().all()) != set(user_ids):
        raise AssigneeNotMember


async def create_item(db: AsyncSession, trip_id: UUID, user_id: UUID, data: dict) -> Item:
    assignee_ids = data.pop("assigned_to", None) or []
    await _ensure_members(db, trip_id, assignee_ids)

    item = Item(trip_id=trip_id, created_by=user_id, **data)
    item.assignees = [ItemAssignee(user_id=uid) for uid in assignee_ids]
    db.add(item)
    await db.commit()
    await db.refresh(item)
    return item


async def list_items(
    db: AsyncSession,
    trip_id: UUID,
    *,
    type_: ItemType | None = None,
    assigned_to: UUID | None = None,
    completed: bool | None = None,
    starts_after: datetime | None = None,
    starts_before: datetime | None = None,
) -> list[Item]:
    """Filters are composed server-side so the client never fetches a whole trip
    to display one day of it."""
    query = select(Item).where(Item.trip_id == trip_id)

    if type_ is not None:
        query = query.where(Item.type == type_)
    if assigned_to is not None:
        query = query.join(ItemAssignee, ItemAssignee.item_id == Item.id).where(
            ItemAssignee.user_id == assigned_to
        )
    if completed is True:
        query = query.where(Item.completed_at.is_not(None))
    elif completed is False:
        query = query.where(Item.completed_at.is_(None))
    if starts_after is not None:
        query = query.where(Item.starts_at >= starts_after)
    if starts_before is not None:
        query = query.where(Item.starts_at <= starts_before)

    # Undated tasks sort last: the calendar comes first, the backlog after.
    query = query.order_by(Item.starts_at.asc().nullslast(), Item.created_at.asc())
    result = await db.execute(query)
    return list(result.scalars().all())


async def get_item(db: AsyncSession, trip_id: UUID, item_id: UUID) -> Item:
    """Both ids are matched: an item id alone must never cross trip boundaries."""
    item = await db.scalar(select(Item).where(Item.id == item_id, Item.trip_id == trip_id))
    if item is None:
        raise ItemNotFound
    return item


async def update_item(db: AsyncSession, item: Item, data: dict) -> Item:
    assignee_ids = data.pop("assigned_to", None)
    if assignee_ids is not None:
        await _ensure_members(db, item.trip_id, assignee_ids)
        # Replaced wholesale: the client sends the set it wants, not a delta,
        # which spares it from tracking what changed.
        item.assignees = [ItemAssignee(user_id=uid) for uid in assignee_ids]

    for key, value in data.items():
        setattr(item, key, value)
    await db.commit()
    await db.refresh(item)
    return item


async def delete_item(db: AsyncSession, item: Item) -> None:
    await db.delete(item)
    await db.commit()


async def set_completion(db: AsyncSession, item: Item, done: bool, user_id: UUID) -> Item:
    if item.type is not ItemType.TASK:
        raise NotATask
    if done:
        # Idempotent: re-tapping a checkbox must not rewrite who finished it.
        if item.completed_at is None:
            item.completed_at = datetime.now(UTC)
            item.completed_by = user_id
    else:
        item.completed_at = None
        item.completed_by = None
    await db.commit()
    await db.refresh(item)
    return item
