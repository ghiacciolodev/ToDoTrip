"""Request and response contracts for authentication endpoints."""

from datetime import datetime
from uuid import UUID

from pydantic import BaseModel, ConfigDict, EmailStr, Field, field_validator


def _trimmed(value: str | None) -> str:
    """Reject a name that is only whitespace, or an explicit null.

    min_length alone would let "   " through and leave the person nameless
    everywhere they appear. Defaults are not validated, so this only ever sees
    a key the client actually sent: absent still means "leave unchanged".
    """
    trimmed = (value or "").strip()
    if not trimmed:
        raise ValueError("must not be blank")
    return trimmed


class UserRegister(BaseModel):
    email: EmailStr
    password: str = Field(min_length=8, max_length=128)
    display_name: str = Field(min_length=1, max_length=100)


class UserLogin(BaseModel):
    email: EmailStr
    password: str


class UserPublic(BaseModel):
    """What the API is allowed to reveal about a user. Note the absence of
    password_hash: this schema is the boundary that makes leaking it impossible."""

    model_config = ConfigDict(from_attributes=True)

    id: UUID
    email: EmailStr
    display_name: str
    created_at: datetime


class UserUpdate(BaseModel):
    """A PATCH: absent means "leave unchanged".

    The email is deliberately not here. Changing it has to prove the new address
    belongs to the person asking, or it becomes a way to take over an account by
    pointing it at your own inbox; that needs a mail round trip the app has no
    sender for yet.
    """

    display_name: str | None = Field(default=None, min_length=1, max_length=100)

    _normalize = field_validator("display_name")(_trimmed)


class PasswordChange(BaseModel):
    current_password: str
    new_password: str = Field(min_length=8, max_length=128)


class TokenPair(BaseModel):
    access_token: str
    refresh_token: str
    token_type: str = "bearer"


class RefreshRequest(BaseModel):
    refresh_token: str
