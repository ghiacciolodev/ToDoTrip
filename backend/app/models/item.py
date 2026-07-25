"""Calendar entries and to-dos, unified into a single table."""

import enum
from datetime import datetime
from uuid import UUID, uuid4

from sqlalchemy import (
    DateTime,
    Enum,
    ForeignKey,
    Index,
    String,
    Text,
    UniqueConstraint,
    Uuid,
)
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.models.base import Base, TimestampMixin


class ItemType(enum.StrEnum):
    EVENT = "event"
    TASK = "task"


class Item(Base, TimestampMixin):
    """Either a scheduled event or a to-do, discriminated by `type`.

    Events and tasks share ~90% of their fields and all of their CRUD, so they
    live in one table: an event is an item with starts_at, a task is an item
    with assignees and a completion.
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

    # Timestamp instead of a boolean: it answers "done?" and "when?" in one column.
    completed_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    completed_by: Mapped[UUID | None] = mapped_column(ForeignKey("users.id", ondelete="SET NULL"))

    created_by: Mapped[UUID] = mapped_column(ForeignKey("users.id"), nullable=False)

    # selectin loading fetches every item's assignees in one extra query rather
    # than one per item, which is the classic N+1 when listing a trip's plan.
    assignees: Mapped[list["ItemAssignee"]] = relationship(
        back_populates="item", cascade="all, delete-orphan", lazy="selectin"
    )


class ItemAssignee(Base):
    """Who is responsible for a task. Several people can share one.

    A join table rather than a column on items: chores like "buy the groceries"
    are routinely split, and when a member leaves the trip only their row goes
    away — the task itself survives with the remaining assignees.
    """

    __tablename__ = "item_assignees"
    __table_args__ = (UniqueConstraint("item_id", "user_id", name="uq_item_assignee"),)

    id: Mapped[UUID] = mapped_column(Uuid, primary_key=True, default=uuid4)
    item_id: Mapped[UUID] = mapped_column(
        ForeignKey("items.id", ondelete="CASCADE"), index=True, nullable=False
    )
    user_id: Mapped[UUID] = mapped_column(
        ForeignKey("users.id", ondelete="CASCADE"), index=True, nullable=False
    )

    item: Mapped["Item"] = relationship(back_populates="assignees")
