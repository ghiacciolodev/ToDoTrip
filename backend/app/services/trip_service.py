"""Trips themselves: creating one, listing them, and what a trip looks like.

Membership lives in member_service, invite codes in invite_service. The split
follows what the rules are about — a trip is a row somebody edits, a membership
is a relationship money can hold shut, an invite is the only door in from
outside.
"""

from datetime import UTC, datetime
from uuid import UUID

from sqlalchemy import func, select, union_all
from sqlalchemy.ext.asyncio import AsyncSession

from app.models import (
    Checklist,
    ChecklistEntry,
    Expense,
    Item,
    MapPin,
    MemberRole,
    Settlement,
    Trip,
    TripMember,
    User,
)

# Balances are read here, not computed here: a trip card shows what you owe,
# and that answer belongs to the money module.
from app.services import expense_service
from app.services.trip_errors import NotAMember, TripNotFound

# How many avatars a trip card shows before collapsing into "+n".
_PREVIEW_MEMBERS = 3


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


async def count_members(db: AsyncSession, trip_id: UUID) -> int:
    """How many people are in a trip.

    Lives here rather than with the membership rules so that member_service can
    depend on this module without this module depending back.
    """
    return await db.scalar(
        select(func.count()).select_from(TripMember).where(TripMember.trip_id == trip_id)
    )


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
