"""Calendar entries and to-dos, unified into a single table."""

import enum
from datetime import datetime
from uuid import UUID, uuid4

from sqlalchemy import DateTime, Enum, ForeignKey, Index, String, Text, Uuid
from sqlalchemy.orm import Mapped, mapped_column

from app.models.base import Base, TimestampMixin


class ItemType(enum.StrEnum):
    EVENT = "event"
    TASK = "task"


class Item(Base, TimestampMixin):
    """Either a scheduled event or a to-do, discriminated by `type`.

    Events and tasks share ~90% of their fields and all of their CRUD, so they
    live in one table: an event is an item with starts_at, a task is an item
    with assigned_to and completed_at.
    """

    __tablename__ = "items"

    # Composite index backing the main calendar query:
    # "items of this trip, ordered by date". Without it PostgreSQL scans the table.
    __table_args__ = (Index("ix_items_trip_starts", "trip_id", "starts_at"),)

    id: Mapped[UUID] = mapped_column(Uuid, primary_key=True, default=uuid4)
    trip_id: Mapped[UUID] = mapped_column(
        ForeignKey("trips.id", ondelete="CASCADE"), index=True, nullable=False
    )
    type: Mapped[ItemType] = mapped_column(
        Enum(ItemType, native_enum=False, length=20), nullable=False
    )
    title: Mapped[str] = mapped_column(String(200), nullable=False)
    description: Mapped[str | None] = mapped_column(Text)
    location: Mapped[str | None] = mapped_column(String(255))

    # Timezone-aware: the trip may cross time zones, and the phone renders local time.
    starts_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    ends_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))

    # SET NULL, not CASCADE: if a member leaves the trip the task survives and
    # simply becomes unassigned. It must not silently disappear.
    assigned_to: Mapped[UUID | None] = mapped_column(
        ForeignKey("users.id", ondelete="SET NULL"), index=True
    )

    # Timestamp instead of a boolean: it answers "done?" and "when?" in one column.
    completed_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    completed_by: Mapped[UUID | None] = mapped_column(ForeignKey("users.id", ondelete="SET NULL"))

    created_by: Mapped[UUID] = mapped_column(ForeignKey("users.id"), nullable=False)
