"""Request and response contracts for checklists and their entries."""

from datetime import datetime
from uuid import UUID

from pydantic import BaseModel, ConfigDict, Field, field_validator


def _trimmed(value: str) -> str:
    """Reject text that is only whitespace.

    Entries are typed in a hurry, often one-handed, so a stray space is common
    and would otherwise store a line that renders as blank.
    """
    trimmed = value.strip()
    if not trimmed:
        raise ValueError("must not be blank")
    return trimmed


class ChecklistCreate(BaseModel):
    name: str = Field(min_length=1, max_length=120)

    _normalize = field_validator("name")(_trimmed)


class ChecklistEntryCreate(BaseModel):
    text: str = Field(min_length=1, max_length=200)

    _normalize = field_validator("text")(_trimmed)


class ChecklistEntryPublic(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: UUID
    checklist_id: UUID
    text: str
    checked_at: datetime | None
    checked_by: UUID | None
    created_at: datetime


class ChecklistPublic(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: UUID
    trip_id: UUID
    name: str
    created_by: UUID
    created_at: datetime
    # Inlined rather than behind a second endpoint: a list is useless without
    # its lines, and the cards need the counts to show progress.
    entries: list[ChecklistEntryPublic] = Field(default_factory=list)
