"""Application user: identity and credentials."""

from uuid import UUID, uuid4

from sqlalchemy import Boolean, String, Uuid
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