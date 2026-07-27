"""HTTP layer for calendar events and tasks."""

from datetime import datetime
from typing import Annotated
from uuid import UUID

from fastapi import APIRouter, HTTPException, Query, status

from app.core.events import Notify, emit
from app.dependencies import CurrentUser, DbSession, Membership, Writable
from app.models import ItemType, NotificationKind
from app.schemas.item import ItemCreate, ItemPublic, ItemUpdate
from app.services import item_service, trip_service
from app.services.item_service import AssigneeNotMember, ItemNotFound, NotATask

# The trip_id in the prefix feeds the Membership dependency, so every route
# below is authorized before its body runs.
router = APIRouter(prefix="/trips/{trip_id}/items", tags=["items"])

_NOT_FOUND = HTTPException(status.HTTP_404_NOT_FOUND, "Item not found")
_BAD_ASSIGNEE = HTTPException(
    status.HTTP_422_UNPROCESSABLE_CONTENT, "Assignee is not a member of this trip"
)
_NOT_A_TASK = HTTPException(status.HTTP_409_CONFLICT, "Only tasks can be completed")


async def _created_notice(db: DbSession, trip_id: UUID, user, item) -> Notify | None:
    """What, if anything, a new plan entry is worth telling people.

    An event goes to the whole trip: it is something the group is now doing at a
    particular hour. A task goes only to the people it was put on — a to-do
    nobody was assigned is a note to the group, and a to-do assigned to Luca is
    not news for the other three. A task with no assignees tells nobody.
    """
    trip = await trip_service.get_trip(db, trip_id)
    if item.type is ItemType.EVENT:
        return Notify(
            kind=NotificationKind.EVENT_ADDED,
            entity_id=item.id,
            payload={
                "actor_name": user.display_name,
                "trip_name": trip.name,
                "title": item.title,
            },
        )

    assignees = [a.user_id for a in item.assignees]
    if not assignees:
        return None
    return Notify(
        kind=NotificationKind.TASK_ASSIGNED,
        entity_id=item.id,
        only=assignees,
        payload={
            "actor_name": user.display_name,
            "trip_name": trip.name,
            "title": item.title,
        },
    )


@router.post("", response_model=ItemPublic, status_code=status.HTTP_201_CREATED)
async def create_item(
    trip_id: UUID, payload: ItemCreate, db: DbSession, user: CurrentUser, _: Writable
):
    try:
        item = await item_service.create_item(db, trip_id, user.id, payload.model_dump())
    except AssigneeNotMember:
        raise _BAD_ASSIGNEE from None
    await emit(
        trip_id,
        "items.changed",
        actor_id=user.id,
        db=db,
        notify=await _created_notice(db, trip_id, user, item),
    )
    return item


@router.get("", response_model=list[ItemPublic])
async def list_items(
    trip_id: UUID,
    db: DbSession,
    _: Membership,
    type: Annotated[ItemType | None, Query()] = None,
    assigned_to: Annotated[UUID | None, Query()] = None,
    completed: Annotated[bool | None, Query()] = None,
    starts_after: Annotated[datetime | None, Query()] = None,
    starts_before: Annotated[datetime | None, Query()] = None,
):
    return await item_service.list_items(
        db,
        trip_id,
        type_=type,
        assigned_to=assigned_to,
        completed=completed,
        starts_after=starts_after,
        starts_before=starts_before,
    )


@router.get("/{item_id}", response_model=ItemPublic)
async def get_item(trip_id: UUID, item_id: UUID, db: DbSession, _: Membership):
    try:
        return await item_service.get_item(db, trip_id, item_id)
    except ItemNotFound:
        raise _NOT_FOUND from None


@router.patch("/{item_id}", response_model=ItemPublic)
async def update_item(
    trip_id: UUID, item_id: UUID, payload: ItemUpdate, db: DbSession, membership: Writable
):
    try:
        item = await item_service.get_item(db, trip_id, item_id)
        item = await item_service.update_item(db, item, payload.model_dump(exclude_unset=True))
    except ItemNotFound:
        raise _NOT_FOUND from None
    except AssigneeNotMember:
        raise _BAD_ASSIGNEE from None
    await emit(trip_id, "items.changed", actor_id=membership.user_id)
    return item


@router.delete("/{item_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_item(trip_id: UUID, item_id: UUID, db: DbSession, membership: Writable):
    """Any member can delete: a shared list nobody can tidy becomes unusable."""
    try:
        await item_service.delete_item(db, await item_service.get_item(db, trip_id, item_id))
    except ItemNotFound:
        raise _NOT_FOUND from None
    await emit(trip_id, "items.changed", actor_id=membership.user_id)


@router.post("/{item_id}/complete", response_model=ItemPublic)
async def complete_item(
    trip_id: UUID, item_id: UUID, db: DbSession, user: CurrentUser, _: Writable
):
    try:
        item = await item_service.get_item(db, trip_id, item_id)
        item = await item_service.set_completion(db, item, True, user.id)
    except ItemNotFound:
        raise _NOT_FOUND from None
    except NotATask:
        raise _NOT_A_TASK from None
    await emit(trip_id, "items.changed", actor_id=user.id)
    return item


@router.delete("/{item_id}/complete", response_model=ItemPublic)
async def reopen_item(trip_id: UUID, item_id: UUID, db: DbSession, user: CurrentUser, _: Writable):
    try:
        item = await item_service.get_item(db, trip_id, item_id)
        item = await item_service.set_completion(db, item, False, user.id)
    except ItemNotFound:
        raise _NOT_FOUND from None
    except NotATask:
        raise _NOT_A_TASK from None
    await emit(trip_id, "items.changed", actor_id=user.id)
    return item
