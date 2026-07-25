"""Authentication use cases. Knows about the database, not about HTTP."""

from datetime import UTC, datetime, timedelta
from uuid import UUID

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.config import get_settings
from app.core import security
from app.models import RefreshToken, User

settings = get_settings()


class AuthError(Exception):
    """Credentials or tokens were rejected. Translated to HTTP 401 by the router."""


class EmailAlreadyUsed(Exception):
    """Registration conflict. Translated to HTTP 409 by the router."""


async def register(db: AsyncSession, email: str, password: str, display_name: str) -> User:
    email = email.lower().strip()
    if await db.scalar(select(User).where(User.email == email)):
        raise EmailAlreadyUsed
    user = User(
        email=email,
        password_hash=security.hash_password(password),
        display_name=display_name.strip(),
    )
    db.add(user)
    await db.commit()
    await db.refresh(user)
    return user


async def authenticate(db: AsyncSession, email: str, password: str) -> User:
    user = await db.scalar(select(User).where(User.email == email.lower().strip()))
    if user is None:
        # Hash anyway so a missing account costs the same time as a wrong
        # password. Otherwise response latency reveals which emails exist.
        security.hash_password(password)
        raise AuthError
    if not user.is_active or not security.verify_password(password, user.password_hash):
        raise AuthError
    return user


async def issue_refresh_token(db: AsyncSession, user_id: UUID) -> str:
    raw, token_hash = security.generate_refresh_token()
    db.add(
        RefreshToken(
            user_id=user_id,
            token_hash=token_hash,
            expires_at=datetime.now(UTC) + timedelta(days=settings.refresh_token_days),
        )
    )
    await db.commit()
    return raw


async def rotate_refresh_token(db: AsyncSession, raw_token: str) -> tuple[User, str]:
    """Consume a refresh token and issue a fresh one.

    Rotation means a stolen token is single-use: whoever loses the race gets a
    revoked token and is locked out, which makes the theft detectable.
    """
    stored = await db.scalar(
        select(RefreshToken).where(RefreshToken.token_hash == security.hash_refresh_token(raw_token))
    )
    if stored is None or stored.revoked_at is not None:
        raise AuthError
    if stored.expires_at <= datetime.now(UTC):
        raise AuthError

    user = await db.get(User, stored.user_id)
    if user is None or not user.is_active:
        raise AuthError

    stored.revoked_at = datetime.now(UTC)
    await db.commit()

    new_raw = await issue_refresh_token(db, user.id)
    return user, new_raw


async def revoke_refresh_token(db: AsyncSession, raw_token: str) -> None:
    """Logout. Idempotent on purpose: an unknown token is not an error."""
    stored = await db.scalar(
        select(RefreshToken).where(RefreshToken.token_hash == security.hash_refresh_token(raw_token))
    )
    if stored is not None and stored.revoked_at is None:
        stored.revoked_at = datetime.now(UTC)
        await db.commit()