"""Map use cases: live member locations and shared pins, scoped to one trip."""

from datetime import UTC, datetime, timedelta
from uuid import UUID

from sqlalchemy import delete, select
from sqlalchemy.dialects.postgresql import insert
from sqlalchemy.ext.asyncio import AsyncSession

from app.models import MapPin, MemberLocation

# How long a reported position stays believable. Sharing runs only while the map
# is open, so a stale row means the app was closed or lost signal — either way
# the honest answer is to stop showing it rather than to show it as current.
LOCATION_TTL = timedelta(minutes=30)


class PinNotFound(Exception):
    """No such pin inside this trip."""


async def upsert_location(
    db: AsyncSession, trip_id: UUID, user_id: UUID, data: dict
) -> MemberLocation:
    """Write where someone is now, replacing where they were.

    One statement with ON CONFLICT rather than select-then-write: positions
    arrive every twenty seconds from several devices, and the read-modify-write
    version would occasionally race itself into a unique violation.
    """
    values = {
        "trip_id": trip_id,
        "user_id": user_id,
        "expires_at": datetime.now(UTC) + LOCATION_TTL,
        **data,
    }
    statement = (
        insert(MemberLocation)
        .values(**values)
        .on_conflict_do_update(
            constraint="uq_member_location",
            set_={
                "latitude": values["latitude"],
                "longitude": values["longitude"],
                "accuracy_m": values.get("accuracy_m"),
                "expires_at": values["expires_at"],
                "updated_at": datetime.now(UTC),
            },
        )
        .returning(MemberLocation)
    )
    location = (await db.execute(statement)).scalar_one()
    await db.commit()
    return location


async def clear_location(db: AsyncSession, trip_id: UUID, user_id: UUID) -> None:
    """Stop sharing: the row goes, rather than being marked hidden.

    Nothing to leak later, and nothing to switch back on by mistake.
    """
    await db.execute(
        delete(MemberLocation).where(
            MemberLocation.trip_id == trip_id, MemberLocation.user_id == user_id
        )
    )
    await db.commit()


async def list_locations(db: AsyncSession, trip_id: UUID) -> list[MemberLocation]:
    """Only positions still inside their TTL: an expired one is not data, it is
    a guess about someone who stopped telling us."""
    result = await db.execute(
        select(MemberLocation).where(
            MemberLocation.trip_id == trip_id,
            MemberLocation.expires_at > datetime.now(UTC),
        )
    )
    return list(result.scalars().all())


async def create_pin(db: AsyncSession, trip_id: UUID, user_id: UUID, data: dict) -> MapPin:
    pin = MapPin(trip_id=trip_id, created_by=user_id, **data)
    db.add(pin)
    await db.commit()
    await db.refresh(pin)
    return pin


async def list_pins(db: AsyncSession, trip_id: UUID) -> list[MapPin]:
    result = await db.execute(
        select(MapPin).where(MapPin.trip_id == trip_id).order_by(MapPin.created_at.asc())
    )
    return list(result.scalars().all())


async def get_pin(db: AsyncSession, trip_id: UUID, pin_id: UUID) -> MapPin:
    """Both ids are matched: a pin id alone must never cross trip boundaries."""
    pin = await db.scalar(select(MapPin).where(MapPin.id == pin_id, MapPin.trip_id == trip_id))
    if pin is None:
        raise PinNotFound
    return pin


async def update_pin(db: AsyncSession, pin: MapPin, data: dict) -> MapPin:
    for key, value in data.items():
        setattr(pin, key, value)
    await db.commit()
    await db.refresh(pin)
    return pin


async def delete_pin(db: AsyncSession, pin: MapPin) -> None:
    await db.delete(pin)
    await db.commit()
