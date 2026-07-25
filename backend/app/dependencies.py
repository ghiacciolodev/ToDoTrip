"""Reusable FastAPI dependencies."""

from typing import Annotated

from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from sqlalchemy.ext.asyncio import AsyncSession

from app.core import security
from app.database import get_db
from app.models import User

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
