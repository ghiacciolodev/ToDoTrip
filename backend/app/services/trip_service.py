"""Trip, membership and invite use cases."""

from datetime import UTC, datetime, timedelta
from uuid import UUID

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.codes import generate_invite_code
from app.models import Invite, MemberRole, Trip, TripMember, User


class TripNotFound(Exception):
    """The trip does not exist, or the caller is not allowed to know it does."""


class NotAMember(Exception):
    """Caller has no membership row for this trip."""


class NotAnOwner(Exception):
    """Caller is a member but lacks the owner role."""


class InvalidInvite(Exception):
    """Code is unknown, revoked, expired or exhausted."""


async def create_trip(db: AsyncSession, user_id: UUID, data: dict) -> Trip:
    """Create a trip and make the author its owner, atomically.

    Both rows are flushed in one transaction: a trip without an owner would be
    unreachable by anyone, including its creator.
    """
    trip = Trip(created_by=user_id, **data)
    db.add(trip)
    await db.flush()
    db.add(TripMember(trip_id=trip.id, user_id=user_id, role=MemberRole.OWNER))
    await db.commit()
    await db.refresh(trip)
    return trip


async def list_trips(db: AsyncSession, user_id: UUID) -> list[Trip]:
    """Only trips the user belongs to. The join IS the authorization filter."""
    result = await db.execute(
        select(Trip)
        .join(TripMember, TripMember.trip_id == Trip.id)
        .where(TripMember.user_id == user_id)
        .order_by(Trip.start_date.desc().nullslast(), Trip.created_at.desc())
    )
    return list(result.scalars().all())


async def get_membership(db: AsyncSession, trip_id: UUID, user_id: UUID) -> TripMember:
    membership = await db.scalar(
        select(TripMember).where(TripMember.trip_id == trip_id, TripMember.user_id == user_id)
    )
    if membership is None:
        raise NotAMember
    return membership


async def get_trip(db: AsyncSession, trip_id: UUID) -> Trip:
    trip = await db.get(Trip, trip_id)
    if trip is None:
        raise TripNotFound
    return trip


async def update_trip(db: AsyncSession, trip: Trip, data: dict) -> Trip:
    # exclude_unset is applied by the router: only keys the client actually
    # sent reach this point, so a PATCH never blanks untouched fields.
    for key, value in data.items():
        setattr(trip, key, value)
    await db.commit()
    await db.refresh(trip)
    return trip


async def delete_trip(db: AsyncSession, trip: Trip) -> None:
    """Removes items, expenses and memberships through ON DELETE CASCADE."""
    await db.delete(trip)
    await db.commit()


async def list_members(db: AsyncSession, trip_id: UUID) -> list[tuple[TripMember, User]]:
    result = await db.execute(
        select(TripMember, User)
        .join(User, User.id == TripMember.user_id)
        .where(TripMember.trip_id == trip_id)
        .order_by(TripMember.joined_at)
    )
    return list(result.all())


async def leave_trip(db: AsyncSession, membership: TripMember) -> None:
    """Owners cannot leave: a trip must always have someone able to manage it.

    They delete the trip instead. Ownership transfer is a v2 concern.
    """
    if membership.role == MemberRole.OWNER:
        raise NotAnOwner
    await db.delete(membership)
    await db.commit()


async def create_invite(
    db: AsyncSession,
    trip_id: UUID,
    user_id: UUID,
    expires_in_hours: int | None,
    max_uses: int | None,
) -> Invite:
    expires_at = datetime.now(UTC) + timedelta(hours=expires_in_hours) if expires_in_hours else None
    # Retry on the astronomically unlikely collision rather than trusting luck;
    # uniqueness is guaranteed by the database, not by the generator.
    for _ in range(5):
        code = generate_invite_code()
        if await db.scalar(select(Invite).where(Invite.code == code)) is None:
            break
    else:
        raise RuntimeError("could not generate a unique invite code")

    invite = Invite(
        trip_id=trip_id,
        code=code,
        created_by=user_id,
        expires_at=expires_at,
        max_uses=max_uses,
    )
    db.add(invite)
    await db.commit()
    await db.refresh(invite)
    return invite


async def list_invites(db: AsyncSession, trip_id: UUID) -> list[Invite]:
    result = await db.execute(
        select(Invite).where(Invite.trip_id == trip_id).order_by(Invite.created_at.desc())
    )
    return list(result.scalars().all())


async def revoke_invite(db: AsyncSession, trip_id: UUID, invite_id: UUID) -> None:
    invite = await db.scalar(
        select(Invite).where(Invite.id == invite_id, Invite.trip_id == trip_id)
    )
    if invite is None:
        raise InvalidInvite
    if invite.revoked_at is None:
        invite.revoked_at = datetime.now(UTC)
        await db.commit()


async def join_by_code(db: AsyncSession, code: str, user_id: UUID) -> Trip:
    """Redeem an invite code.

    Idempotent: a member re-opening the link gets their trip back without
    burning a use, because sharing a link in a group chat guarantees re-taps.
    """
    invite = await db.scalar(select(Invite).where(Invite.code == code.strip().upper()))
    if invite is None or invite.revoked_at is not None:
        raise InvalidInvite
    if invite.expires_at is not None and invite.expires_at <= datetime.now(UTC):
        raise InvalidInvite

    existing = await db.scalar(
        select(TripMember).where(
            TripMember.trip_id == invite.trip_id, TripMember.user_id == user_id
        )
    )
    if existing is not None:
        return await get_trip(db, invite.trip_id)

    if invite.max_uses is not None and invite.uses_count >= invite.max_uses:
        raise InvalidInvite

    db.add(TripMember(trip_id=invite.trip_id, user_id=user_id, role=MemberRole.MEMBER))
    # Incremented in SQL rather than in Python: two people redeeming the same
    # link at once would otherwise both read the old value and lose a count.
    invite.uses_count = Invite.uses_count + 1
    await db.commit()
    return await get_trip(db, invite.trip_id)
