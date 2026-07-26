"""The shared map: places the group saved, and where its members are now."""

import enum
from datetime import datetime
from uuid import UUID, uuid4

from sqlalchemy import (
    CheckConstraint,
    DateTime,
    Enum,
    Float,
    ForeignKey,
    String,
    Text,
    UniqueConstraint,
    Uuid,
    func,
)
from sqlalchemy.orm import Mapped, mapped_column

from app.models.base import Base, TimestampMixin


def _coordinate_bounds(prefix: str) -> tuple[CheckConstraint, CheckConstraint]:
    """Latitude and longitude bounds, enforced by the database.

    Pydantic already rejects them, but a coordinate outside these ranges is
    nonsense that would render as a marker in the sea, and the schema is the
    only guard that survives a script, a migration or a future endpoint.
    """
    return (
        CheckConstraint("latitude >= -90 AND latitude <= 90", name=f"ck_{prefix}_latitude"),
        CheckConstraint("longitude >= -180 AND longitude <= 180", name=f"ck_{prefix}_longitude"),
    )


class PinCategory(enum.StrEnum):
    LODGING = "lodging"
    FOOD = "food"
    MEETING_POINT = "meeting_point"
    PARKING = "parking"
    SIGHT = "sight"
    OTHER = "other"


class MapPin(Base, TimestampMixin):
    """A place the group saved.

    Its own table rather than another ItemType: a pin has no date, is never
    completed and is never assigned, and items already carries events, tasks and
    the rows that back lists. Sharing a table would leave most columns empty on
    every row of both kinds.
    """

    __tablename__ = "map_pins"
    __table_args__ = _coordinate_bounds("pin")

    id: Mapped[UUID] = mapped_column(Uuid, primary_key=True, default=uuid4)
    trip_id: Mapped[UUID] = mapped_column(
        ForeignKey("trips.id", ondelete="CASCADE"), index=True, nullable=False
    )
    name: Mapped[str] = mapped_column(String(120), nullable=False)
    description: Mapped[str | None] = mapped_column(Text)

    latitude: Mapped[float] = mapped_column(Float, nullable=False)
    longitude: Mapped[float] = mapped_column(Float, nullable=False)

    # native_enum=False stores a VARCHAR with a CHECK: adding a category later
    # is a trivial migration, where a native enum would need ALTER TYPE.
    category: Mapped[PinCategory] = mapped_column(
        Enum(PinCategory, native_enum=False, length=20),
        default=PinCategory.OTHER,
        nullable=False,
    )

    created_by: Mapped[UUID] = mapped_column(ForeignKey("users.id"), nullable=False)


class MemberLocation(Base):
    """Where a member is right now. Not a history: one row per member, overwritten.

    Nothing here is kept: the moment the row expires it stops being readable,
    and stopping sharing deletes it outright. A trail of where someone has been
    is a different product with different consent, and this table is shaped so
    it cannot accidentally become one.
    """

    __tablename__ = "member_locations"

    # One row per member per trip, which is what makes the upsert possible.
    __table_args__ = (
        UniqueConstraint("trip_id", "user_id", name="uq_member_location"),
        *_coordinate_bounds("location"),
    )

    id: Mapped[UUID] = mapped_column(Uuid, primary_key=True, default=uuid4)
    trip_id: Mapped[UUID] = mapped_column(
        ForeignKey("trips.id", ondelete="CASCADE"), index=True, nullable=False
    )
    user_id: Mapped[UUID] = mapped_column(
        ForeignKey("users.id", ondelete="CASCADE"), index=True, nullable=False
    )

    latitude: Mapped[float] = mapped_column(Float, nullable=False)
    longitude: Mapped[float] = mapped_column(Float, nullable=False)

    # Metres of uncertainty, as reported by the device. Null when it says nothing.
    accuracy_m: Mapped[float | None] = mapped_column(Float)

    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), onupdate=func.now(), nullable=False
    )

    # Without this, someone who closes the app stays pinned to where they were
    # two hours ago, and everyone else believes it. Readers filter on it.
    expires_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)
