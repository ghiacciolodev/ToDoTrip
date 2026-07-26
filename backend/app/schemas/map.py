"""Request and response contracts for map pins and member locations.

Every coordinate is bounded here and again by a CHECK on the table: a value
outside these ranges is not a small error, it is a marker somewhere in the sea.
"""

from datetime import datetime
from uuid import UUID

from pydantic import BaseModel, ConfigDict, Field

from app.models import PinCategory


class LocationUpdate(BaseModel):
    latitude: float = Field(ge=-90, le=90)
    longitude: float = Field(ge=-180, le=180)
    # Metres. Bounded so a confused device cannot claim a circle the size of a
    # continent, which would draw as a useless blur over the whole map.
    accuracy_m: float | None = Field(default=None, ge=0, le=100_000)


class LocationPublic(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    user_id: UUID
    latitude: float
    longitude: float
    accuracy_m: float | None
    updated_at: datetime
    expires_at: datetime


class PinCreate(BaseModel):
    name: str = Field(min_length=1, max_length=120)
    description: str | None = Field(default=None, max_length=2000)
    latitude: float = Field(ge=-90, le=90)
    longitude: float = Field(ge=-180, le=180)
    category: PinCategory = PinCategory.OTHER


class PinUpdate(BaseModel):
    """PATCH semantics: absent means unchanged."""

    name: str | None = Field(default=None, min_length=1, max_length=120)
    description: str | None = Field(default=None, max_length=2000)
    latitude: float | None = Field(default=None, ge=-90, le=90)
    longitude: float | None = Field(default=None, ge=-180, le=180)
    category: PinCategory | None = None


class PinPublic(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: UUID
    trip_id: UUID
    name: str
    description: str | None
    latitude: float
    longitude: float
    category: PinCategory
    created_by: UUID
    created_at: datetime
