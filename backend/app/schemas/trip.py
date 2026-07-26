"""Request and response contracts for trips, membership and invites."""

from datetime import date, datetime
from uuid import UUID

from pydantic import BaseModel, ConfigDict, Field, model_validator

from app.models import MemberRole
from app.schemas.auth import UserPublic


class TripCreate(BaseModel):
    name: str = Field(min_length=1, max_length=120)
    description: str | None = Field(default=None, max_length=2000)
    start_date: date | None = None
    end_date: date | None = None
    base_currency: str = Field(default="EUR", min_length=3, max_length=3)

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
    created_by: UUID
    created_at: datetime


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
