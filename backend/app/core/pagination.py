"""Keyset pagination, shared by every list that can grow without bound.

Not offsets. With `OFFSET 30` a row inserted while somebody is reading shifts
everything down by one, so page two opens with a row they have already seen —
and on a list sorted newest-first, insertions are the normal case rather than
the exception.

The key is always a timestamp plus the row id. The timestamp alone is not
enough: rows written by one request share it to the microsecond, and a page
boundary landing inside such a group would drop or repeat its members.
"""

from base64 import urlsafe_b64decode, urlsafe_b64encode
from dataclasses import dataclass
from datetime import datetime
from uuid import UUID

from sqlalchemy import ColumnElement, Select, func, select, tuple_
from sqlalchemy.ext.asyncio import AsyncSession

# The most a caller can ask for in one request, so `limit=100000` cannot be
# used to pull a whole trip's history in one go.
MAX_PAGE = 100
DEFAULT_PAGE = 30


@dataclass(frozen=True, slots=True)
class Page[T]:
    """One page, plus how to ask for the next and how many there are in total.

    `total` is a second query, and it is worth it: without it a screen that says
    "14 expenses" can only count what it has loaded, which is a number that
    changes as you scroll. A count over an indexed column is cheap; a wrong
    figure on screen is not.
    """

    items: list[T]
    next_cursor: str | None
    total: int


def encode_cursor(at: datetime, row_id: UUID) -> str:
    """Opaque on purpose: the client hands it back untouched, so how pages are
    cut can change without a client release."""
    return urlsafe_b64encode(f"{at.isoformat()}|{row_id}".encode()).decode()


def decode_cursor(cursor: str | None) -> tuple[datetime, UUID] | None:
    if not cursor:
        return None
    try:
        at, row_id = urlsafe_b64decode(cursor.encode()).decode().split("|", 1)
        return datetime.fromisoformat(at), UUID(row_id)
    except (ValueError, TypeError):
        # A cursor that does not parse gives the first page rather than a 500:
        # a mangled query string is not worth an error page.
        return None


async def paginate[T](
    db: AsyncSession,
    query: Select,
    *,
    sort_column: ColumnElement,
    id_column: ColumnElement,
    limit: int = DEFAULT_PAGE,
    before: str | None = None,
) -> Page[T]:
    """Run `query` as one page, newest first.

    `query` carries the filtering and nothing else — no ordering, no limit.
    Those belong here so every list is cut the same way.
    """
    limit = max(1, min(limit, MAX_PAGE))

    total = await db.scalar(select(func.count()).select_from(query.order_by(None).subquery()))

    page = query.order_by(sort_column.desc(), id_column.desc()).limit(limit + 1)
    if (cursor := decode_cursor(before)) is not None:
        page = page.where(tuple_(sort_column, id_column) < tuple_(*cursor))

    rows = list((await db.execute(page)).scalars().all())

    # One more than asked for was fetched: whether a next page exists is
    # answered by whether that extra row came back, with no second query.
    if len(rows) > limit:
        last = rows[limit - 1]
        return Page(
            items=rows[:limit],
            next_cursor=encode_cursor(getattr(last, sort_column.key), getattr(last, id_column.key)),
            total=total or 0,
        )
    return Page(items=rows, next_cursor=None, total=total or 0)
