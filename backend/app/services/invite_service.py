"""Invite codes, and redeeming one.

Its own module because an invite is the only way somebody outside a trip can
reach it: the rules about what makes a code still valid are worth reading
without the rest of the trip logic around them.
"""

from datetime import UTC, datetime, timedelta
from uuid import UUID

from sqlalchemy import delete, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.codes import generate_invite_code
from app.models import Invite, MemberRole, Trip, TripMember, TripPastMember
from app.services import trip_service
from app.services.trip_errors import InvalidInvite


async def create_invite(
    db: AsyncSession,
    trip_id: UUID,
    user_id: UUID,
    expires_in_hours: int | None,
    max_uses: int | None,
) -> Invite:
    expires_at = datetime.now(UTC) + timedelta(hours=expires_in_hours) if expires_in_hours else None
    # Retry on the astronomically unlikely collision rather than trusting luck;
    # uniqueness is guaranteed by the database, not by the generator.
    for _ in range(5):
        code = generate_invite_code()
        if await db.scalar(select(Invite).where(Invite.code == code)) is None:
            break
    else:
        raise RuntimeError("could not generate a unique invite code")

    invite = Invite(
        trip_id=trip_id,
        code=code,
        created_by=user_id,
        expires_at=expires_at,
        max_uses=max_uses,
    )
    db.add(invite)
    await db.commit()
    await db.refresh(invite)
    return invite


async def list_invites(db: AsyncSession, trip_id: UUID) -> list[Invite]:
    result = await db.execute(
        select(Invite).where(Invite.trip_id == trip_id).order_by(Invite.created_at.desc())
    )
    return list(result.scalars().all())


async def revoke_invite(db: AsyncSession, trip_id: UUID, invite_id: UUID) -> None:
    invite = await db.scalar(
        select(Invite).where(Invite.id == invite_id, Invite.trip_id == trip_id)
    )
    if invite is None:
        raise InvalidInvite
    if invite.revoked_at is None:
        invite.revoked_at = datetime.now(UTC)
        await db.commit()


async def join_by_code(db: AsyncSession, code: str, user_id: UUID) -> Trip:
    """Redeem an invite code.

    Idempotent: a member re-opening the link gets their trip back without
    burning a use, because sharing a link in a group chat guarantees re-taps.
    """
    invite = await db.scalar(select(Invite).where(Invite.code == code.strip().upper()))
    if invite is None or invite.revoked_at is not None:
        raise InvalidInvite
    if invite.expires_at is not None and invite.expires_at <= datetime.now(UTC):
        raise InvalidInvite

    existing = await db.scalar(
        select(TripMember).where(
            TripMember.trip_id == invite.trip_id, TripMember.user_id == user_id
        )
    )
    if existing is not None:
        return await trip_service.get_trip(db, invite.trip_id)

    if invite.max_uses is not None and invite.uses_count >= invite.max_uses:
        raise InvalidInvite

    db.add(TripMember(trip_id=invite.trip_id, user_id=user_id, role=MemberRole.MEMBER))
    # Someone coming back is a member again, not a former one.
    await db.execute(
        delete(TripPastMember).where(
            TripPastMember.trip_id == invite.trip_id, TripPastMember.user_id == user_id
        )
    )
    # Incremented in SQL rather than in Python: two people redeeming the same
    # link at once would otherwise both read the old value and lose a count.
    invite.uses_count = Invite.uses_count + 1
    await db.commit()
    return await trip_service.get_trip(db, invite.trip_id)
