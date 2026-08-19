"""Trip, membership and invite use cases."""

from datetime import UTC, datetime, timedelta
from uuid import UUID

from sqlalchemy import delete, func, select, union_all, update
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.codes import generate_invite_code
from app.models import (
    Checklist,
    ChecklistEntry,
    Expense,
    Invite,
    Item,
    ItemAssignee,
    MapPin,
    MemberLocation,
    MemberRole,
    Settlement,
    Trip,
    TripMember,
    TripPastMember,
    User,
)

# Membership and money are one rule, not two: nobody may walk away from a trip
# with an open balance, so this module has to be able to ask what someone owes.
from app.services import expense_service

# How many avatars a trip card shows before collapsing into "+n".
_PREVIEW_MEMBERS = 3


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


class NoLongerOwner(Exception):
    """Somebody else handed the trip on first.

    Raised when a transfer finds the caller is no longer the owner — which only
    happens if two transfers were in flight at once.
    """


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


async def list_trips(db: AsyncSession, user_id: UUID, *, archived: bool = False) -> list[Trip]:
    """Only trips the user belongs to. The join IS the authorization filter.

    Archived ones are a separate list rather than a flag on the same one: a trip
    that is over should stop competing for the top of the screen, but it is kept
    precisely so it can still be opened and read.
    """
    condition = Trip.archived_at.is_not(None) if archived else Trip.archived_at.is_(None)
    result = await db.execute(
        select(Trip)
        .join(TripMember, TripMember.trip_id == Trip.id)
        .where(TripMember.user_id == user_id, condition)
        .order_by(Trip.start_date.desc().nullslast(), Trip.created_at.desc())
    )
    return list(result.scalars().all())


async def last_activity(db: AsyncSession, trip_ids: list[UUID]) -> dict[UUID, datetime]:
    """When something last happened in each trip.

    "Activity" is anything a member would recognise as such: a plan entry added
    or edited, an expense, a repayment, a list, a line ticked off it, a pin. The
    trip's own row is one of the sources too, so a brand new empty trip has a
    timestamp instead of a blank line — every trip always gets an answer.

    One query for all of them: the union is grouped and reduced by the database,
    which is the difference between one round trip and six per trip.
    """
    if not trip_ids:
        return {}

    sources = union_all(
        # Covers creation and any later rename or change of dates.
        select(Trip.id.label("trip_id"), Trip.updated_at.label("at")).where(Trip.id.in_(trip_ids)),
        select(Item.trip_id, Item.updated_at).where(Item.trip_id.in_(trip_ids)),
        select(Expense.trip_id, Expense.updated_at).where(Expense.trip_id.in_(trip_ids)),
        select(Settlement.trip_id, Settlement.created_at).where(Settlement.trip_id.in_(trip_ids)),
        select(MapPin.trip_id, MapPin.updated_at).where(MapPin.trip_id.in_(trip_ids)),
        select(Checklist.trip_id, Checklist.updated_at).where(Checklist.trip_id.in_(trip_ids)),
        # Entries have no updated_at, and ticking one is the most frequent thing
        # anybody does in a trip: without this branch an actively used shopping
        # list would read as untouched since the day it was written.
        select(
            Checklist.trip_id,
            func.greatest(
                ChecklistEntry.created_at,
                func.coalesce(ChecklistEntry.checked_at, ChecklistEntry.created_at),
            ),
        )
        .join(ChecklistEntry, ChecklistEntry.checklist_id == Checklist.id)
        .where(Checklist.trip_id.in_(trip_ids)),
    ).subquery()

    rows = await db.execute(
        select(sources.c.trip_id, func.max(sources.c.at)).group_by(sources.c.trip_id)
    )
    return {trip_id: at for trip_id, at in rows}


async def list_trips_with_summary(
    db: AsyncSession, user_id: UUID, *, archived: bool = False
) -> list[dict]:
    """The trips list as one screen needs it, in a bounded number of queries.

    Four round trips regardless of how many trips there are: the trips, then
    every member of those trips, then every expense share and settlement, then
    the last activity of each. The obvious alternative — let each card fetch its
    own members and balance — is an N+1 that a phone feels the moment someone
    has ten trips.

    Balances are still derived, never stored; this only moves the same
    arithmetic to where the rows already are.
    """
    trips = await list_trips(db, user_id, archived=archived)
    if not trips:
        return []
    trip_ids = [trip.id for trip in trips]

    members = (
        await db.execute(
            select(TripMember.trip_id, User.id, User.display_name, TripMember.joined_at)
            .join(User, User.id == TripMember.user_id)
            .where(TripMember.trip_id.in_(trip_ids))
            .order_by(TripMember.joined_at)
        )
    ).all()

    counts: dict[UUID, int] = {}
    previews: dict[UUID, list[dict]] = {}
    for trip_id, member_id, display_name, _ in members:
        counts[trip_id] = counts.get(trip_id, 0) + 1
        # Oldest first, capped: the card shows three avatars and a count.
        preview = previews.setdefault(trip_id, [])
        if len(preview) < _PREVIEW_MEMBERS:
            preview.append({"id": member_id, "display_name": display_name})

    balances = await expense_service.balances_for_trips(db, trip_ids, user_id)
    activity = await last_activity(db, trip_ids)

    rows = [
        {
            "trip": trip,
            "member_count": counts.get(trip.id, 0),
            "member_preview": previews.get(trip.id, []),
            "my_balance_cents": balances.get(trip.id),
            "last_activity_at": activity.get(trip.id, trip.updated_at),
        }
        for trip in trips
    ]
    # Most recently touched first: the list is a place people return to, and the
    # trip they were just in is the one they want at the top — not the one whose
    # departure date happens to be furthest out.
    rows.sort(key=lambda row: row["last_activity_at"], reverse=True)
    return rows


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


async def trip_details(db: AsyncSession, trip: Trip) -> dict:
    """The aggregates the settings screen shows, in three counting queries.

    Counted in the database rather than by fetching the rows: the screen wants
    the number 14, not fourteen expenses.
    """
    members = await count_members(db, trip.id)
    items = await db.scalar(select(func.count()).select_from(Item).where(Item.trip_id == trip.id))
    # One pass for both, since they come off the same rows.
    expenses, total = (
        await db.execute(
            select(func.count(), func.coalesce(func.sum(Expense.amount_cents), 0)).where(
                Expense.trip_id == trip.id
            )
        )
    ).one()

    author = await db.scalar(select(User.display_name).where(User.id == trip.created_by))
    return {
        "member_count": members,
        "item_count": items,
        "expense_count": expenses,
        "total_spent_cents": total,
        # Empty after that account was closed; the client falls back to its own
        # placeholder rather than being handed English from the server.
        "created_by_name": author or None,
    }


async def update_trip(db: AsyncSession, trip: Trip, data: dict) -> Trip:
    # exclude_unset is applied by the router: only keys the client actually
    # sent reach this point, so a PATCH never blanks untouched fields.
    archived = data.pop("archived", None)
    if archived is not None:
        # Re-archiving an archived trip keeps the original timestamp: the date
        # it was put away is a fact, and a stray second tap should not rewrite it.
        if archived and trip.archived_at is None:
            trip.archived_at = datetime.now(UTC)
        elif not archived:
            trip.archived_at = None

    for key, value in data.items():
        setattr(trip, key, value)
    await db.commit()
    await db.refresh(trip)
    return trip


async def set_muted(db: AsyncSession, membership: TripMember, muted: bool) -> TripMember:
    membership.muted = muted
    await db.commit()
    await db.refresh(membership)
    return membership


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
