"""Checklist use cases, all scoped to a single trip."""

from datetime import UTC, datetime
from uuid import UUID

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models import Checklist, ChecklistEntry


class ChecklistNotFound(Exception):
    """No such checklist inside this trip."""


class EntryNotFound(Exception):
    """No such entry inside this checklist."""


async def create_checklist(db: AsyncSession, trip_id: UUID, user_id: UUID, data: dict) -> Checklist:
    checklist = Checklist(trip_id=trip_id, created_by=user_id, **data)
    db.add(checklist)
    await db.commit()
    await db.refresh(checklist)
    return checklist


async def list_checklists(db: AsyncSession, trip_id: UUID) -> list[Checklist]:
    query = (
        select(Checklist).where(Checklist.trip_id == trip_id).order_by(Checklist.created_at.asc())
    )
    result = await db.execute(query)
    return list(result.scalars().all())


async def get_checklist(db: AsyncSession, trip_id: UUID, checklist_id: UUID) -> Checklist:
    """Both ids are matched: a checklist id alone must never cross trip boundaries."""
    checklist = await db.scalar(
        select(Checklist).where(Checklist.id == checklist_id, Checklist.trip_id == trip_id)
    )
    if checklist is None:
        raise ChecklistNotFound
    return checklist


async def delete_checklist(db: AsyncSession, checklist: Checklist) -> None:
    """Entries go with it, by cascade: a list without its lines is nothing."""
    await db.delete(checklist)
    await db.commit()


async def add_entry(db: AsyncSession, checklist: Checklist, data: dict) -> ChecklistEntry:
    entry = ChecklistEntry(checklist_id=checklist.id, **data)
    db.add(entry)
    await db.commit()
    await db.refresh(entry)
    return entry


async def get_entry(db: AsyncSession, checklist_id: UUID, entry_id: UUID) -> ChecklistEntry:
    """Scoped to its checklist, which the caller has already scoped to the trip."""
    entry = await db.scalar(
        select(ChecklistEntry).where(
            ChecklistEntry.id == entry_id, ChecklistEntry.checklist_id == checklist_id
        )
    )
    if entry is None:
        raise EntryNotFound
    return entry


async def delete_entry(db: AsyncSession, entry: ChecklistEntry) -> None:
    await db.delete(entry)
    await db.commit()


async def set_checked(
    db: AsyncSession, entry: ChecklistEntry, checked: bool, user_id: UUID
) -> ChecklistEntry:
    if checked:
        # Idempotent: two people ticking the same line must not rewrite who got it.
        if entry.checked_at is None:
            entry.checked_at = datetime.now(UTC)
            entry.checked_by = user_id
    else:
        entry.checked_at = None
        entry.checked_by = None
    await db.commit()
    await db.refresh(entry)
    return entry
