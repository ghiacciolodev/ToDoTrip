"""Joining, leaving, being removed, and handing a trip on.

Split from trip_service because the rules are different in kind: a trip is a
row somebody edits, while a membership is a relationship that money can hold
shut. Nobody may walk away from an open balance, which is why this module is
the one that has to ask what a member owes.
"""

from uuid import UUID

from sqlalchemy import delete, select, update
from sqlalchemy.ext.asyncio import AsyncSession

from app.models import (
    Item,
    ItemAssignee,
    MemberLocation,
    MemberRole,
    TripMember,
    TripPastMember,
    User,
)

# Two dependencies, both deliberate. Money, because a member with an open
# balance may not leave. Trips, because the last member leaving takes the trip
# with them.
from app.services import expense_service, trip_service
from app.services.trip_errors import (
    NoLongerOwner,
    OutstandingBalance,
    OwnerMustTransfer,
)


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


async def _ensure_settled(db: AsyncSession, trip_id: UUID, user_id: UUID) -> None:
    balance = await expense_service.balance_for(db, trip_id, user_id)
    if balance != 0:
        raise OutstandingBalance(user_id, balance)


async def remove_member(db: AsyncSession, membership: TripMember) -> None:
    """Drop a membership and everything that only made sense while it existed.

    Task assignments go: the task itself stays, it just loses one of the people
    responsible for it. Their shared location goes too, or they would sit on the
    group's map for up to half an hour after losing access to it. Expenses,
    shares and settlements are kept — they record money that actually moved, and
    deleting them would rewrite what everyone else owes. Because those rows
    survive, the person is remembered in trip_past_members so their name can
    still be shown next to them.
    """
    await db.execute(
        delete(ItemAssignee).where(
            ItemAssignee.user_id == membership.user_id,
            ItemAssignee.item_id.in_(select(Item.id).where(Item.trip_id == membership.trip_id)),
        )
    )
    await db.execute(
        delete(MemberLocation).where(
            MemberLocation.trip_id == membership.trip_id,
            MemberLocation.user_id == membership.user_id,
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
    if await trip_service.count_members(db, membership.trip_id) == 1:
        await trip_service.delete_trip(db, await trip_service.get_trip(db, membership.trip_id))
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

    Handing it to the current owner is a no-op rather than an error: the end
    state the caller asked for already holds.

    The demotion is a compare-and-swap — an UPDATE that only matches while the
    caller is *still* the owner — and this is the whole point of the function.
    Reading the role and then writing both rows looks atomic because it sits in
    one transaction, and is not: two transfers starting together would each see
    a trip with one owner, each demote the same person, and each promote a
    different one, leaving two owners and no way for either to be undone. Here
    the second one matches no row and is told so.

    The order matters too. A partial unique index allows one OWNER per trip and
    Postgres checks it per statement, so promoting before demoting would trip
    over an owner who is on their way out.
    """
    if target.user_id == owner.user_id:
        return

    demoted = await db.execute(
        update(TripMember)
        .where(TripMember.id == owner.id, TripMember.role == MemberRole.OWNER)
        .values(role=MemberRole.MEMBER)
    )
    if demoted.rowcount == 0:
        await db.rollback()
        raise NoLongerOwner

    # Flushed before the promotion so the two statements reach the database in
    # the order the index needs, rather than in whatever order a unit of work
    # decides to emit them.
    await db.flush()
    await db.execute(
        update(TripMember).where(TripMember.id == target.id).values(role=MemberRole.OWNER)
    )
    await db.commit()

    # The caller still holds the rows as they were before the raw UPDATEs.
    db.expire(owner)
    db.expire(target)
