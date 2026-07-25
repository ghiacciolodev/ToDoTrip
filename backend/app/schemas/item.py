"""Request and response contracts for calendar events and tasks."""

from datetime import UTC, datetime
from uuid import UUID

from pydantic import BaseModel, ConfigDict, Field, field_validator, model_validator

from app.models import ItemType


def _as_utc(value: datetime | None) -> datetime | None:
    """Attach UTC to naive datetimes.

    The columns are timestamptz, so a naive value would be stored under an
    unstated assumption. Clients across time zones make that a real bug.
    """
    if value is not None and value.tzinfo is None:
        return value.replace(tzinfo=UTC)
    return value


class ItemCreate(BaseModel):
    type: ItemType
    title: str = Field(min_length=1, max_length=200)
    description: str | None = Field(default=None, max_length=2000)
    location: str | None = Field(default=None, max_length=255)
    starts_at: datetime | None = None
    ends_at: datetime | None = None
    assigned_to: UUID | None = None

    _normalize = field_validator("starts_at", "ends_at")(_as_utc)

    @model_validator(mode="after")
    def check_semantics(self):
        # An event with no date could never appear on a calendar.
        if self.type is ItemType.EVENT and self.starts_at is None:
            raise ValueError("an event requires starts_at")
        if self.type is ItemType.EVENT and self.assigned_to is not None:
            raise ValueError("only tasks can be assigned")
        if self.ends_at and self.starts_at and self.ends_at < self.starts_at:
            raise ValueError("ends_at must not precede starts_at")
        return self


class ItemUpdate(BaseModel):
    """PATCH semantics: absent means unchanged, explicit null means cleared."""

    title: str | None = Field(default=None, min_length=1, max_length=200)
    description: str | None = Field(default=None, max_length=2000)
    location: str | None = Field(default=None, max_length=255)
    starts_at: datetime | None = None
    ends_at: datetime | None = None
    assigned_to: UUID | None = None

    _normalize = field_validator("starts_at", "ends_at")(_as_utc)

    @model_validator(mode="after")
    def check_range(self):
        if self.ends_at and self.starts_at and self.ends_at < self.starts_at:
            raise ValueError("ends_at must not precede starts_at")
        return self


class ItemPublic(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: UUID
    trip_id: UUID
    type: ItemType
    title: str
    description: str | None
    location: str | None
    starts_at: datetime | None
    ends_at: datetime | None
    assigned_to: UUID | None
    completed_at: datetime | None
    completed_by: UUID | None
    created_by: UUID
    created_at: datetime
