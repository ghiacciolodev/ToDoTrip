"""Invite codes used to join a trip without knowing its internal id."""

from datetime import datetime
from uuid import UUID, uuid4

from sqlalchemy import DateTime, ForeignKey, Integer, String, Uuid, func
from sqlalchemy.orm import Mapped, mapped_column

from app.models.base import Base


class Invite(Base):
    """A shareable code or link granting membership to one trip.

    Expiry and usage limits are optional: NULL means "no limit", which is the
    common case for a group of friends sharing a link in a chat.
    """

    __tablename__ = "invites"

    id: Mapped[UUID] = mapped_column(Uuid, primary_key=True, default=uuid4)
    trip_id: Mapped[UUID] = mapped_column(
        ForeignKey("trips.id", ondelete="CASCADE"), index=True, nullable=False
    )

    # Short and human-readable because it gets dictated out loud; generated from
    # an alphabet without 0/O/1/I. Uniqueness is enforced by the database.
    code: Mapped[str] = mapped_column(String(12), unique=True, index=True, nullable=False)

    created_by: Mapped[UUID] = mapped_column(ForeignKey("users.id"), nullable=False)
    expires_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    max_uses: Mapped[int | None] = mapped_column(Integer)
    uses_count: Mapped[int] = mapped_column(Integer, default=0, nullable=False)

    # Lets the owner kill a leaked link without deleting the row (keeps the audit trail).
    revoked_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))

    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), nullable=False
    )
