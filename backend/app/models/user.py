"""Application user: identity and credentials."""

from datetime import datetime
from uuid import UUID, uuid4

from sqlalchemy import Boolean, DateTime, String, Uuid
from sqlalchemy.orm import Mapped, mapped_column

from app.models.base import Base, TimestampMixin


class User(Base, TimestampMixin):
    __tablename__ = "users"

    # UUID instead of a sequential integer: user ids travel in URLs and payloads,
    # and sequential ids would let anyone enumerate the whole user base.
    id: Mapped[UUID] = mapped_column(Uuid, primary_key=True, default=uuid4)

    email: Mapped[str] = mapped_column(String(255), unique=True, index=True, nullable=False)

    # Argon2 hash, never the plaintext password.
    password_hash: Mapped[str] = mapped_column(String(255), nullable=False)

    display_name: Mapped[str] = mapped_column(String(100), nullable=False)

    # Soft disable: deleting a user would cascade into trips, expenses and history.
    is_active: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False)

    # When the privacy policy was accepted, and which version of it.
    #
    # Recorded rather than assumed. A tick box enforced only by the sign-up
    # screen is not a record: the endpoint can be called directly, and after the
    # document is edited nobody could say what any given user was actually
    # shown. Nullable because accounts created before this existed have no
    # honest value to put here, and inventing one would be worse than the gap.
    privacy_accepted_at: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True), nullable=True
    )
    privacy_version: Mapped[str | None] = mapped_column(String(20), nullable=True)
