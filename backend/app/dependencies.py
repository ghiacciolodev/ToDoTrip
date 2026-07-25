"""Reusable FastAPI dependencies: authentication and trip-scoped authorization."""

from typing import Annotated
from uuid import UUID

from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from sqlalchemy.ext.asyncio import AsyncSession

from app.core import security
from app.database import get_db
from app.models import MemberRole, TripMember, User
from app.services import trip_service
from app.services.trip_service import NotAMember

# auto_error=False so we control the error shape ourselves.
_bearer = HTTPBearer(auto_error=False)

DbSession = Annotated[AsyncSession, Depends(get_db)]

_UNAUTHORIZED = HTTPException(
    status_code=status.HTTP_401_UNAUTHORIZED,
    detail="Not authenticated",
    headers={"WWW-Authenticate": "Bearer"},
)


async def get_current_user(
    db: DbSession,
    credentials: Annotated[HTTPAuthorizationCredentials | None, Depends(_bearer)],
) -> User:
    if credentials is None:
        raise _UNAUTHORIZED
    user_id = security.decode_access_token(credentials.credentials)
    if user_id is None:
        raise _UNAUTHORIZED
    user = await db.get(User, user_id)
    if user is None or not user.is_active:
        raise _UNAUTHORIZED
    return user


# Every protected endpoint declares `user: CurrentUser` and gets auth for free.
CurrentUser = Annotated[User, Depends(get_current_user)]


async def get_membership(trip_id: UUID, db: DbSession, user: CurrentUser) -> TripMember:
    """Authorize the caller for one specific trip.

    This is the single defence against IDOR: without it, swapping a UUID in the
    URL would expose another group's calendar and expenses. Declaring it once
    per endpoint makes forgetting it hard.

    Non-members get 404, not 403: a 403 would confirm that the trip exists.
    """
    try:
        return await trip_service.get_membership(db, trip_id, user.id)
    except NotAMember:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Trip not found") from None


Membership = Annotated[TripMember, Depends(get_membership)]


async def get_ownership(membership: Membership) -> TripMember:
    """Restrict an endpoint to the trip owner. Builds on Membership, so the
    404-for-strangers rule still applies before the role is ever checked."""
    if membership.role != MemberRole.OWNER:
        raise HTTPException(status.HTTP_403_FORBIDDEN, "Owner role required")
    return membership


Ownership = Annotated[TripMember, Depends(get_ownership)]
