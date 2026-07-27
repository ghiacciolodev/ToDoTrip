"""Turning a trip's ledger into a spreadsheet somebody can open."""

import csv
import io
import re
from urllib.parse import quote
from uuid import UUID

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models import Expense, Trip, TripMember, TripPastMember, User

# Excel and Sheets treat a cell starting with any of these as a formula. A
# description someone typed as "=1+1" is text, but "=cmd|..." pasted into a
# trip and opened by a member is a known attack on the person who opens it.
_FORMULA_START = ("=", "+", "-", "@", "\t", "\r")


def _safe(value: str) -> str:
    """Neutralise a cell that a spreadsheet would otherwise execute."""
    return "'" + value if value.startswith(_FORMULA_START) else value


def _amount(cents: int) -> str:
    """Plain decimal, no thousands separator and no symbol.

    The currency is named once in the header instead: a symbol in every cell is
    what stops a spreadsheet from treating the column as numbers.
    """
    return f"{cents / 100:.2f}"


async def _people(db: AsyncSession, trip_id: UUID) -> list[tuple[UUID, str]]:
    """Everyone who has a column, current members and former ones alike.

    People who left keep their column: they are in expenses that are still in
    the file, and a share with no owner would not add up.
    """
    current = await db.execute(
        select(User.id, User.display_name, TripMember.joined_at)
        .join(TripMember, TripMember.user_id == User.id)
        .where(TripMember.trip_id == trip_id)
    )
    past = await db.execute(
        select(User.id, User.display_name, TripPastMember.joined_at)
        .join(TripPastMember, TripPastMember.user_id == User.id)
        .where(TripPastMember.trip_id == trip_id)
    )
    rows = sorted([*current.all(), *past.all()], key=lambda row: row[2])
    # A closed account has no name left; the column still has to be labelled.
    return [(row[0], row[1] or "—") for row in rows]


async def expenses_csv(db: AsyncSession, trip: Trip) -> str:
    """One row per expense, one column per person.

    The per-person columns are the point: a total tells you what the trip cost,
    the split tells you why somebody owes what they owe, and that is the thing
    people want to check outside the app.
    """
    people = await _people(db, trip.id)
    currency = trip.base_currency

    expenses = (
        (
            await db.execute(
                select(Expense).where(Expense.trip_id == trip.id).order_by(Expense.spent_at)
            )
        )
        .scalars()
        .all()
    )

    buffer = io.StringIO()
    writer = csv.writer(buffer)
    writer.writerow(
        [
            "Date",
            "Description",
            "Paid by",
            f"Amount ({currency})",
            *[f"{name} ({currency})" for _, name in people],
        ]
    )

    names = {user_id: name for user_id, name in people}
    for expense in expenses:
        shares = {share.user_id: share.share_cents for share in expense.shares}
        writer.writerow(
            [
                expense.spent_at.date().isoformat(),
                _safe(expense.description),
                _safe(names.get(expense.paid_by, "—")),
                _amount(expense.amount_cents),
                # Blank, not zero, for someone who was not in this expense:
                # "did not take part" and "owes nothing" read differently in a
                # column of numbers.
                *[_amount(shares[user_id]) if user_id in shares else "" for user_id, _ in people],
            ]
        )

    total = sum(expense.amount_cents for expense in expenses)
    if expenses:
        writer.writerow([])
        writer.writerow(
            [
                "",
                "Total",
                "",
                _amount(total),
                *[
                    _amount(
                        sum(
                            share.share_cents
                            for expense in expenses
                            for share in expense.shares
                            if share.user_id == user_id
                        )
                    )
                    for user_id, _ in people
                ],
            ]
        )

    return buffer.getvalue()


def content_disposition(trip_name: str) -> str:
    """`TripName-expenses.csv`, in a header that cannot be broken by the name.

    Trip names are free text: a quote or a newline in one would otherwise let
    the name rewrite the response headers. The ASCII form is stripped down to
    what is safe, and the real name travels in the RFC 5987 parameter that
    clients prefer when they understand it.
    """
    stem = re.sub(r"[^A-Za-z0-9._-]+", "-", trip_name).strip("-") or "trip"
    encoded = quote(f"{trip_name}-expenses.csv", safe="")
    return f"attachment; filename=\"{stem}-expenses.csv\"; filename*=UTF-8''{encoded}"
