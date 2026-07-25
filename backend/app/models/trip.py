"""Trips and their membership. A trip is the tenant boundary of the whole app."""

import enum
from datetime import date
from uuid import UUID, uuid4

from sqlalchemy import Date, Enum, ForeignKey, String, Text, UniqueConstraint, Uuid
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.models.base import Base, TimestampMixin


class MemberRole(enum.StrEnum):
    OWNER = "owner"
    MEMBER = "member"


class Trip(Base, TimestampMixin):
    """A shared trip. Every item, expense and settlement hangs off a trip."""

    __tablename__ = "trips"

    id: Mapped[UUID] = mapped_column(Uuid, primary_key=True, default=uuid4)
    name: Mapped[str] = mapped_column(String(120), nullable=False)
    description: Mapped[str | None] = mapped_column(Text)

    # Nullable: a trip is often created before the dates are settled.
    start_date: Mapped[date | None] = mapped_column(Date)
    end_date: Mapped[date | None] = mapped_column(Date)

    # ISO 4217 code. All expenses of a trip are reported in this currency.
    base_currency: Mapped[str] = mapped_column(String(3), default="EUR", nullable=False)

    created_by: Mapped[UUID] = mapped_column(ForeignKey("users.id"), nullable=False)

    members: Mapped[list["TripMember"]] = relationship(
        back_populates="trip", cascade="all, delete-orphan"
    )


class TripMember(Base):
    """Join table between users and trips. Presence of a row IS the authorization."""

    __tablename__ = "trip_members"

    # Guards against joining the same trip twice, e.g. by reusing an invite link.
    __table_args__ = (UniqueConstraint("trip_id", "user_id", name="uq_trip_member"),)

    id: Mapped[UUID] = mapped_column(Uuid, primary_key=True, default=uuid4)
    trip_id: Mapped[UUID] = mapped_column(
        ForeignKey("trips.id", ondelete="CASCADE"), index=True, nullable=False
    )
    user_id: Mapped[UUID] = mapped_column(
        ForeignKey("users.id", ondelete="CASCADE"), index=True, nullable=False
    )

    # native_enum=False stores a VARCHAR with a CHECK constraint. Adding a role
    # later is a trivial migration; a native PostgreSQL enum would need ALTER TYPE.
    role: Mapped[MemberRole] = mapped_column(
        Enum(MemberRole, native_enum=False, length=20), default=MemberRole.MEMBER, nullable=False
    )

    trip: Mapped["Trip"] = relationship(back_populates="members")
