"""Request and response contracts for trips, membership and invites."""

from datetime import date, datetime
from uuid import UUID

from pydantic import BaseModel, ConfigDict, Field, field_validator, model_validator

from app.core.currency import normalise as normalise_currency
from app.models import MemberRole
from app.schemas.auth import UserPublic


class TripCreate(BaseModel):
    name: str = Field(min_length=1, max_length=120)
    description: str | None = Field(default=None, max_length=2000)
    start_date: date | None = None
    end_date: date | None = None
    base_currency: str = Field(default="EUR", min_length=3, max_length=3)

    _check_currency = field_validator("base_currency")(lambda cls, value: normalise_currency(value))

    # Symbolic keys the client understands; the server only stores them. Kept
    # loose on purpose: adding a thirteenth icon must not need a backend change.
    icon: str | None = Field(default=None, max_length=30)
    color: str | None = Field(default=None, max_length=30)

    @model_validator(mode="after")
    def check_dates(self):
        # Enforced here rather than in the database so the client gets a clear
        # 422 instead of an opaque integrity error.
        if self.start_date and self.end_date and self.end_date < self.start_date:
            raise ValueError("end_date must not precede start_date")
        return self


class TripUpdate(BaseModel):
    """All fields optional: this is a PATCH, absent means "leave unchanged"."""

    name: str | None = Field(default=None, min_length=1, max_length=120)
    description: str | None = Field(default=None, max_length=2000)
    start_date: date | None = None
    end_date: date | None = None
    base_currency: str | None = Field(default=None, min_length=3, max_length=3)
    icon: str | None = Field(default=None, max_length=30)
    color: str | None = Field(default=None, max_length=30)

    # A boolean on the way in, a timestamp in the table: the client is saying
    # "put this away" or "bring it back", and when that happened is the server's
    # business to record.
    archived: bool | None = None

    _check_currency = field_validator("base_currency")(
        lambda cls, value: value if value is None else normalise_currency(value)
    )


class TripPublic(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: UUID
    name: str
    description: str | None
    start_date: date | None
    end_date: date | None
    base_currency: str
    icon: str | None
    color: str | None
    archived_at: datetime | None
    created_by: UUID
    created_at: datetime


class TripDetail(TripPublic):
    """One trip, with what its settings screen puts on the page.

    The counts and the total are aggregates rather than lists: the screen shows
    "14 expenses", and sending fourteen expenses to render the number 14 would
    be the same waste the trips list was fixed for.
    """

    member_count: int
    expense_count: int
    item_count: int
    # Sum of every expense, in the trip's own currency. Settlements are excluded
    # deliberately: a repayment moves money between two members, it is not part
    # of what the trip cost.
    total_spent_cents: int
    # Denormalised for one line of text: "Created by Mario on 3 June".
    created_by_name: str | None


class MemberPreview(BaseModel):
    """Just enough of a member to draw an avatar."""

    model_config = ConfigDict(from_attributes=True)

    id: UUID
    display_name: str


class TripSummary(TripPublic):
    """A trip as the list screen needs it.

    The three extra fields exist so a list of ten trips is one request instead
    of twenty-one: without them each card would have to fetch its own members
    and its own balance, which is the classic N+1 and is felt immediately on a
    phone. They are computed server-side, where the joins are cheap.
    """

    member_count: int
    # The first few, oldest first, for the overlapping avatars on the card.
    member_preview: list[MemberPreview]
    # The signed-in caller's net position, or null when the trip has no
    # expenses at all — "settled" and "nothing spent yet" are different things
    # and the card says them differently.
    my_balance_cents: int | None
    # When anything last happened here. Never null: a trip with nothing in it
    # falls back to its own row, so the card always has a line to show. The list
    # arrives sorted by this, most recent first.
    last_activity_at: datetime


class MemberSettings(BaseModel):
    """What one person decides about one trip, for themselves alone."""

    muted: bool


class MemberPublic(BaseModel):
    user: UserPublic
    role: MemberRole
    joined_at: datetime

    # Set only for former members. They are listed so the client can still put a
    # name on the expenses they took part in; anything that picks people — an
    # assignee, a payer, a split — must use the ones where this is null.
    left_at: datetime | None = None


class InviteCreate(BaseModel):
    expires_in_hours: int | None = Field(default=None, ge=1, le=24 * 30)
    max_uses: int | None = Field(default=None, ge=1, le=100)


class InvitePublic(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: UUID
    code: str
    expires_at: datetime | None
    max_uses: int | None
    uses_count: int
    revoked_at: datetime | None
    created_at: datetime


class JoinRequest(BaseModel):
    code: str = Field(min_length=4, max_length=12)
