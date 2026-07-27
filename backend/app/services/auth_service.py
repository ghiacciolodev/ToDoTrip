"""Authentication use cases. Knows about the database, not about HTTP."""

from datetime import UTC, datetime, timedelta
from uuid import UUID, uuid4

from sqlalchemy import delete, select, update
from sqlalchemy.ext.asyncio import AsyncSession

from app.config import get_settings
from app.core import security
from app.models import (
    MemberLocation,
    MemberRole,
    RefreshToken,
    Trip,
    TripMember,
    User,
)

settings = get_settings()


class AuthError(Exception):
    """Credentials or tokens were rejected. Translated to HTTP 401 by the router."""


class EmailAlreadyUsed(Exception):
    """Registration conflict. Translated to HTTP 409 by the router."""


class StillOwnsTrips(Exception):
    """The account owns trips other people are still in.

    Deleting it would leave those groups with nobody who can invite, rename or
    close them. Handing them over is a decision only their owner can make, so
    the request is refused rather than resolved by guessing a new owner.
    """

    def __init__(self, trip_ids: list[UUID]) -> None:
        self.trip_ids = trip_ids
        super().__init__(f"still owns {len(trip_ids)} trips")


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
        select(RefreshToken).where(
            RefreshToken.token_hash == security.hash_refresh_token(raw_token)
        )
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
        select(RefreshToken).where(
            RefreshToken.token_hash == security.hash_refresh_token(raw_token)
        )
    )
    if stored is not None and stored.revoked_at is None:
        stored.revoked_at = datetime.now(UTC)
        await db.commit()


async def revoke_all_refresh_tokens(db: AsyncSession, user_id: UUID) -> None:
    """Drop every session this account has anywhere.

    Written as one UPDATE rather than a loop: the point is that no session
    survives, and fetching the rows first would leave a window in which one
    issued in between is missed.
    """
    await db.execute(
        update(RefreshToken)
        .where(RefreshToken.user_id == user_id, RefreshToken.revoked_at.is_(None))
        .values(revoked_at=datetime.now(UTC))
    )
    await db.commit()


async def update_profile(db: AsyncSession, user: User, data: dict) -> User:
    # exclude_unset is applied by the router, so absent keys never reach here.
    for key, value in data.items():
        setattr(user, key, value.strip() if isinstance(value, str) else value)
    await db.commit()
    await db.refresh(user)
    return user


async def change_password(db: AsyncSession, user: User, current: str, new: str) -> str:
    """Replace the password and end every other session. Returns a fresh refresh token.

    Someone changing their password because they think another person is in
    their account is the case that matters: leaving the other sessions alive
    would make the change pointless. Every token is revoked, including the
    caller's own, and a new one is handed back — the alternative, sparing the
    token the caller sent, would mean carrying it in the request body just to
    keep it alive, which puts it in one more log and buys nothing.
    """
    if not security.verify_password(current, user.password_hash):
        raise AuthError

    user.password_hash = security.hash_password(new)
    await db.commit()

    await revoke_all_refresh_tokens(db, user.id)
    return await issue_refresh_token(db, user.id)


async def owned_trips_with_others(db: AsyncSession, user_id: UUID) -> list[UUID]:
    """Trips this user owns that other people are also in.

    A trip they are alone in is not an obstacle: it goes when they go, the same
    rule `leave_trip` already applies.
    """
    others = select(TripMember.trip_id).where(TripMember.user_id != user_id).scalar_subquery()
    result = await db.execute(
        select(TripMember.trip_id).where(
            TripMember.user_id == user_id,
            TripMember.role == MemberRole.OWNER,
            TripMember.trip_id.in_(others),
        )
    )
    return list(result.scalars().all())


async def delete_account(db: AsyncSession, user: User) -> None:
    """Close an account without rewriting anyone else's history.

    The row is emptied rather than deleted. Expenses, shares and settlements
    point at it, and they record money that actually moved: removing them would
    silently change what everyone else owes, and removing only the user would
    leave the ledger showing amounts next to nobody. So the identifying fields
    go — email, name, password — and what stays is an anonymous marker the
    ledger can still resolve to "someone who was here".

    Refused while they still own a trip other people are in; trips they were
    alone in are deleted with them, the same rule `leave_trip` already applies.

    Note what is deliberately *not* checked: an outstanding balance. Leaving a
    single trip is blocked by one, but closing an account is a right, and making
    it conditional on settling a debt inside the app is not a condition this is
    allowed to impose. What they owe survives in the ledger; the person does not.
    """
    owned = await owned_trips_with_others(db, user.id)
    if owned:
        raise StillOwnsTrips(owned)

    solo = await db.execute(
        select(TripMember.trip_id).where(
            TripMember.user_id == user.id, TripMember.role == MemberRole.OWNER
        )
    )
    for trip_id in solo.scalars().all():
        await db.execute(delete(Trip).where(Trip.id == trip_id))

    # Memberships in other people's trips, and any position still on their map.
    await db.execute(delete(TripMember).where(TripMember.user_id == user.id))
    await db.execute(delete(MemberLocation).where(MemberLocation.user_id == user.id))

    # A reserved TLD, so the placeholder can never collide with a real address
    # nor be mailed by accident, and unique so a second deletion still fits.
    user.email = f"deleted+{uuid4().hex}@deleted.invalid"
    user.display_name = ""
    # Not a valid hash for any input: the account cannot be logged into again.
    user.password_hash = "!"
    user.is_active = False
    await db.commit()

    await revoke_all_refresh_tokens(db, user.id)
