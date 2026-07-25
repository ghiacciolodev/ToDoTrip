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


class TripPublic(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: UUID
    name: str
    description: str | None
    start_date: date | None
    end_date: date | None
    base_currency: str
    created_by: UUID
    created_at: datetime


class MemberPublic(BaseModel):
    user: UserPublic
    role: MemberRole
    joined_at: datetime


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
