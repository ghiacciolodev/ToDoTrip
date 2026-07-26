"""HTTP layer for checklists and their entries."""

from uuid import UUID

from fastapi import APIRouter, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.dependencies import CurrentUser, DbSession, Membership
from app.schemas.checklist import (
    ChecklistCreate,
    ChecklistEntryCreate,
    ChecklistEntryPublic,
    ChecklistPublic,
)
from app.services import checklist_service
from app.services.checklist_service import ChecklistNotFound, EntryNotFound

# The trip_id in the prefix feeds the Membership dependency, so every route
# below is authorized before its body runs.
router = APIRouter(prefix="/trips/{trip_id}/checklists", tags=["checklists"])

_NOT_FOUND = HTTPException(status.HTTP_404_NOT_FOUND, "Checklist not found")
_ENTRY_NOT_FOUND = HTTPException(status.HTTP_404_NOT_FOUND, "Entry not found")


@router.post("", response_model=ChecklistPublic, status_code=status.HTTP_201_CREATED)
async def create_checklist(
    trip_id: UUID, payload: ChecklistCreate, db: DbSession, user: CurrentUser, _: Membership
):
    return await checklist_service.create_checklist(db, trip_id, user.id, payload.model_dump())


@router.get("", response_model=list[ChecklistPublic])
async def list_checklists(trip_id: UUID, db: DbSession, _: Membership):
    return await checklist_service.list_checklists(db, trip_id)


@router.delete("/{checklist_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_checklist(trip_id: UUID, checklist_id: UUID, db: DbSession, _: Membership):
    """Any member can delete, as for items: a shared list nobody can tidy
    becomes unusable."""
    try:
        checklist = await checklist_service.get_checklist(db, trip_id, checklist_id)
        await checklist_service.delete_checklist(db, checklist)
    except ChecklistNotFound:
        raise _NOT_FOUND from None


@router.post(
    "/{checklist_id}/entries",
    response_model=ChecklistEntryPublic,
    status_code=status.HTTP_201_CREATED,
)
async def add_entry(
    trip_id: UUID,
    checklist_id: UUID,
    payload: ChecklistEntryCreate,
    db: DbSession,
    _: Membership,
):
    try:
        checklist = await checklist_service.get_checklist(db, trip_id, checklist_id)
        return await checklist_service.add_entry(db, checklist, payload.model_dump())
    except ChecklistNotFound:
        raise _NOT_FOUND from None


@router.delete("/{checklist_id}/entries/{entry_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_entry(
    trip_id: UUID, checklist_id: UUID, entry_id: UUID, db: DbSession, _: Membership
):
    try:
        checklist = await checklist_service.get_checklist(db, trip_id, checklist_id)
        entry = await checklist_service.get_entry(db, checklist.id, entry_id)
        await checklist_service.delete_entry(db, entry)
    except ChecklistNotFound:
        raise _NOT_FOUND from None
    except EntryNotFound:
        raise _ENTRY_NOT_FOUND from None


@router.post("/{checklist_id}/entries/{entry_id}/check", response_model=ChecklistEntryPublic)
async def check_entry(
    trip_id: UUID,
    checklist_id: UUID,
    entry_id: UUID,
    db: DbSession,
    user: CurrentUser,
    _: Membership,
):
    return await _set_checked(db, trip_id, checklist_id, entry_id, True, user.id)


@router.delete("/{checklist_id}/entries/{entry_id}/check", response_model=ChecklistEntryPublic)
async def uncheck_entry(
    trip_id: UUID,
    checklist_id: UUID,
    entry_id: UUID,
    db: DbSession,
    user: CurrentUser,
    _: Membership,
):
    return await _set_checked(db, trip_id, checklist_id, entry_id, False, user.id)


async def _set_checked(
    db: AsyncSession,
    trip_id: UUID,
    checklist_id: UUID,
    entry_id: UUID,
    checked: bool,
    user_id: UUID,
):
    """Shared by check and uncheck: both resolve the same two ids first, so the
    404s stay identical."""
    try:
        checklist = await checklist_service.get_checklist(db, trip_id, checklist_id)
        entry = await checklist_service.get_entry(db, checklist.id, entry_id)
        return await checklist_service.set_checked(db, entry, checked, user_id)
    except ChecklistNotFound:
        raise _NOT_FOUND from None
    except EntryNotFound:
        raise _ENTRY_NOT_FOUND from None
