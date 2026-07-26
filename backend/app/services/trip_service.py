"""Trip, membership and invite use cases."""

from datetime import UTC, datetime, timedelta
from uuid import UUID

from sqlalchemy import delete, func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.codes import generate_invite_code
from app.models import (
    Invite,
    Item,
    ItemAssignee,
    MemberRole,
    Trip,
    TripMember,
    TripPastMember,
    User,
)

# Membership and money are one rule, not two: nobody may walk away from a trip
# with an open balance, so this module has to be able to ask what someone owes.
from app.services import expense_service


class TripNotFound(Exception):
    """The trip does not exist, or the caller is not allowed to know it does."""


class NotAMember(Exception):
    """Caller has no membership row for this trip."""


class OwnerMustTransfer(Exception):
    """An owner cannot step out while other members remain.

    A trip always has exactly one owner: leaving without handing it over would
    leave a group nobody can invite to, rename or delete.
    """


class OutstandingBalance(Exception):
    """This member still owes money, or is still owed some.

    Departure is blocked rather than resolved afterwards. Their expenses cannot
    be deleted — that would silently change what everyone else owes — and a
    former member has no name in the app and no way to be paid back, so the
    balance would sit there unresolvable. Settling first is one rule that
    removes the whole problem.
    """

    def __init__(self, user_id: UUID, balance_cents: int) -> None:
        self.user_id = user_id
        self.balance_cents = balance_cents
        super().__init__(f"{user_id} has a balance of {balance_cents} cents")


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


async def list_past_members(db: AsyncSession, trip_id: UUID) -> list[tuple[TripPastMember, User]]:
    """People who were here. Returned to the client for one reason: their name
    still appears beside expenses they took part in."""
    result = await db.execute(
        select(TripPastMember, User)
        .join(User, User.id == TripPastMember.user_id)
        .where(TripPastMember.trip_id == trip_id)
        .order_by(TripPastMember.left_at)
    )
    return list(result.all())


async def count_members(db: AsyncSession, trip_id: UUID) -> int:
    return await db.scalar(
        select(func.count()).select_from(TripMember).where(TripMember.trip_id == trip_id)
    )


async def _ensure_settled(db: AsyncSession, trip_id: UUID, user_id: UUID) -> None:
    balance = await expense_service.balance_for(db, trip_id, user_id)
    if balance != 0:
        raise OutstandingBalance(user_id, balance)


async def remove_member(db: AsyncSession, membership: TripMember) -> None:
    """Drop a membership and everything that only made sense while it existed.

    Task assignments go: the task itself stays, it just loses one of the people
    responsible for it. Expenses, shares and settlements are kept — they record
    money that actually moved, and deleting them would rewrite what everyone
    else owes. Because those rows survive, the person is remembered in
    trip_past_members so their name can still be shown next to them.
    """
    await db.execute(
        delete(ItemAssignee).where(
            ItemAssignee.user_id == membership.user_id,
            ItemAssignee.item_id.in_(select(Item.id).where(Item.trip_id == membership.trip_id)),
        )
    )
    # Replaces any earlier record of the same person leaving the same trip.
    await db.execute(
        delete(TripPastMember).where(
            TripPastMember.trip_id == membership.trip_id,
            TripPastMember.user_id == membership.user_id,
        )
    )
    db.add(
        TripPastMember(
            trip_id=membership.trip_id,
            user_id=membership.user_id,
            role=membership.role,
            joined_at=membership.joined_at,
        )
    )
    await db.delete(membership)
    await db.commit()


async def leave_trip(db: AsyncSession, membership: TripMember) -> bool:
    """Remove the caller from a trip. True when that deleted the trip itself.

    Being the last one is checked before anything else: someone alone in a trip
    has nobody to owe and nobody to hand it to, so the only sensible reading of
    "leave" is that the trip goes with them. The caller confirms that first.
    """
    if await count_members(db, membership.trip_id) == 1:
        await delete_trip(db, await get_trip(db, membership.trip_id))
        return True

    if membership.role == MemberRole.OWNER:
        raise OwnerMustTransfer

    await _ensure_settled(db, membership.trip_id, membership.user_id)
    await remove_member(db, membership)
    return False


async def remove_by_owner(db: AsyncSession, owner: TripMember, target: TripMember) -> None:
    """Kick someone out. The owner is not allowed to kick themselves: their way
    out is to hand the trip over first, or to delete it."""
    if target.user_id == owner.user_id:
        raise OwnerMustTransfer

    await _ensure_settled(db, target.trip_id, target.user_id)
    await remove_member(db, target)


async def transfer_ownership(db: AsyncSession, owner: TripMember, target: TripMember) -> None:
    """Hand the trip to another member.

    Both rows change in one transaction, so there is no instant at which the
    trip has two owners or none. Handing it to the current owner is a no-op
    rather than an error: the end state the caller asked for already holds.
    """
    if target.user_id == owner.user_id:
        return

    target.role = MemberRole.OWNER
    owner.role = MemberRole.MEMBER
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
    # Someone coming back is a member again, not a former one.
    await db.execute(
        delete(TripPastMember).where(
            TripPastMember.trip_id == invite.trip_id, TripPastMember.user_id == user_id
        )
    )
    # Incremented in SQL rather than in Python: two people redeeming the same
    # link at once would otherwise both read the old value and lose a count.
    invite.uses_count = Invite.uses_count + 1
    await db.commit()
    return await get_trip(db, invite.trip_id)
