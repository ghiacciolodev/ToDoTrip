"""Checklists: a named heading with many short lines to tick off."""

from datetime import datetime
from uuid import UUID, uuid4

from sqlalchemy import DateTime, ForeignKey, String, Uuid, func
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.models.base import Base, TimestampMixin


class Checklist(Base, TimestampMixin):
    """A container of short entries, e.g. the groceries.

    Deliberately not an Item: a task ("book the hostel") is one piece of work
    with assignees and a deadline, while a checklist is one heading with twenty
    throwaway lines under it. Folding both into the items table would leave half
    of its columns empty on every row and make the calendar query wider.
    """

    __tablename__ = "checklists"

    id: Mapped[UUID] = mapped_column(Uuid, primary_key=True, default=uuid4)
    trip_id: Mapped[UUID] = mapped_column(
        ForeignKey("trips.id", ondelete="CASCADE"), index=True, nullable=False
    )
    name: Mapped[str] = mapped_column(String(120), nullable=False)
    created_by: Mapped[UUID] = mapped_column(ForeignKey("users.id"), nullable=False)

    # Entries travel with their list: a card has to show "4 of 12" before anyone
    # opens it, so fetching them separately would mean a request per card.
    # selectin loads them all in one extra query instead of one per list.
    entries: Mapped[list["ChecklistEntry"]] = relationship(
        back_populates="checklist",
        cascade="all, delete-orphan",
        lazy="selectin",
        order_by="ChecklistEntry.created_at",
    )


class ChecklistEntry(Base):
    """One line of a checklist.

    No assignees and no deadline: these are picked up in the moment, by whoever
    is holding the phone in the shop, and the only state worth keeping is
    whether someone has already got it.
    """

    __tablename__ = "checklist_entries"

    id: Mapped[UUID] = mapped_column(Uuid, primary_key=True, default=uuid4)
    checklist_id: Mapped[UUID] = mapped_column(
        ForeignKey("checklists.id", ondelete="CASCADE"), index=True, nullable=False
    )
    text: Mapped[str] = mapped_column(String(200), nullable=False)

    # Timestamp instead of a boolean, as for tasks: it answers "taken?" and
    # "when?" in one column.
    checked_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    checked_by: Mapped[UUID | None] = mapped_column(ForeignKey("users.id", ondelete="SET NULL"))

    # Entries are appended and never edited, so updated_at would be dead weight.
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), nullable=False
    )

    checklist: Mapped["Checklist"] = relationship(back_populates="entries")
