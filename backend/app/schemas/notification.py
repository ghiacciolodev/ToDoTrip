"""Request and response contracts for the notification feed."""

from datetime import datetime
from uuid import UUID

from pydantic import BaseModel, ConfigDict

from app.models import NotificationKind


class NotificationPublic(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: UUID
    trip_id: UUID
    kind: NotificationKind
    actor_id: UUID | None
    entity_id: UUID | None
    # Raw facts. The client turns these into a sentence with its own
    # translations, so a change of language does not leave the history written
    # in the previous one.
    payload: dict
    read_at: datetime | None
    created_at: datetime


class NotificationFeed(BaseModel):
    """A page, plus how to ask for the one after it.

    The cursor is opaque: it encodes a timestamp and an id, and the client's
    only job is to hand it back. Making it opaque means the pagination scheme
    can change without a client release.
    """

    items: list[NotificationPublic]
    next_cursor: str | None


class UnreadCount(BaseModel):
    count: int


class MarkRead(BaseModel):
    ids: list[UUID]
