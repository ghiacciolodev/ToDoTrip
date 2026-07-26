"""HTTP layer for trips, membership and invites."""

from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, status

from app.core.rate_limit import throttle
from app.dependencies import CurrentUser, DbSession, Membership, Ownership
from app.schemas.auth import UserPublic
from app.schemas.trip import (
    InviteCreate,
    InvitePublic,
    JoinRequest,
    MemberPublic,
    TripCreate,
    TripPublic,
    TripUpdate,
)
from app.services import trip_service
from app.services.trip_service import (
    InvalidInvite,
    NotAMember,
    OutstandingBalance,
    OwnerMustTransfer,
)

router = APIRouter(prefix="/trips", tags=["trips"])

_MEMBER_NOT_FOUND = HTTPException(status.HTTP_404_NOT_FOUND, "Member not found")


def _conflict(code: str, message: str, **extra) -> HTTPException:
    """A 409 the client can act on.

    The detail carries a machine-readable code because the app has to tell
    "hand the trip over first" from "settle up first", and for the second one it
    needs the amount to name it on screen. A prose message alone would force the
    client to match on English text.
    """
    return HTTPException(status.HTTP_409_CONFLICT, {"code": code, "message": message, **extra})


def _owner_must_transfer() -> HTTPException:
    return _conflict(
        "owner_must_transfer",
        "Make someone else the owner first.",
    )


def _outstanding_balance(error: OutstandingBalance) -> HTTPException:
    return _conflict(
        "outstanding_balance",
        "Settle up first.",
        user_id=str(error.user_id),
        balance_cents=error.balance_cents,
    )


@router.post("", response_model=TripPublic, status_code=status.HTTP_201_CREATED)
async def create_trip(payload: TripCreate, db: DbSession, user: CurrentUser):
    return await trip_service.create_trip(db, user.id, payload.model_dump())


@router.get("", response_model=list[TripPublic])
async def list_trips(db: DbSession, user: CurrentUser):
    return await trip_service.list_trips(db, user.id)


# Declared before the /{trip_id} routes so "join" is never parsed as an id.
# Throttled because this is the one endpoint where guessing pays off: a valid
# code grants access to a group's whole calendar and ledger.
@router.post(
    "/join",
    response_model=TripPublic,
    dependencies=[Depends(throttle(limit=20, window_seconds=3600, scope="join"))],
)
async def join_trip(payload: JoinRequest, db: DbSession, user: CurrentUser):
    try:
        return await trip_service.join_by_code(db, payload.code, user.id)
    except InvalidInvite:
        raise HTTPException(status.HTTP_400_BAD_REQUEST, "Invalid or expired invite") from None


@router.get("/{trip_id}", response_model=TripPublic)
async def get_trip(trip_id: UUID, db: DbSession, membership: Membership):
    return await trip_service.get_trip(db, trip_id)


@router.patch("/{trip_id}", response_model=TripPublic)
async def update_trip(trip_id: UUID, payload: TripUpdate, db: DbSession, _: Ownership):
    trip = await trip_service.get_trip(db, trip_id)
    # exclude_unset: a PATCH must not blank fields the client did not send.
    return await trip_service.update_trip(db, trip, payload.model_dump(exclude_unset=True))


@router.delete("/{trip_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_trip(trip_id: UUID, db: DbSession, _: Ownership):
    await trip_service.delete_trip(db, await trip_service.get_trip(db, trip_id))


@router.get("/{trip_id}/members", response_model=list[MemberPublic])
async def list_members(trip_id: UUID, db: DbSession, membership: Membership):
    """Current members first, then anyone who has left.

    Former members are included with a `left_at` so their name stays available
    for the expenses they were part of, which outlive their membership. They hold
    no access: this list is descriptive, the membership table is what authorizes.
    """
    return await _members(db, trip_id)


async def _members(db: DbSession, trip_id: UUID) -> list[MemberPublic]:
    rows = [
        *await trip_service.list_members(db, trip_id),
        *await trip_service.list_past_members(db, trip_id),
    ]
    return [
        MemberPublic(
            user=UserPublic.model_validate(user),
            role=m.role,
            joined_at=m.joined_at,
            # Only the historical rows carry one.
            left_at=getattr(m, "left_at", None),
        )
        for m, user in rows
    ]


# Declared before /members/{user_id} so "me" is never parsed as a user id.
@router.delete("/{trip_id}/members/me", status_code=status.HTTP_204_NO_CONTENT)
async def leave_trip(db: DbSession, membership: Membership):
    """Leave a trip, or delete it when leaving would empty it.

    An owner must hand the trip over first, and nobody may leave with an open
    balance: both are answered with a 409 carrying a code, because the app shows
    a different way forward for each.
    """
    try:
        await trip_service.leave_trip(db, membership)
    except OwnerMustTransfer:
        raise _owner_must_transfer() from None
    except OutstandingBalance as e:
        raise _outstanding_balance(e) from None


@router.delete("/{trip_id}/members/{user_id}", status_code=status.HTTP_204_NO_CONTENT)
async def remove_member(trip_id: UUID, user_id: UUID, db: DbSession, owner: Ownership):
    """Remove someone else from the trip. Owner only."""
    try:
        target = await trip_service.get_membership(db, trip_id, user_id)
    except NotAMember:
        raise _MEMBER_NOT_FOUND from None

    try:
        await trip_service.remove_by_owner(db, owner, target)
    except OwnerMustTransfer:
        raise _owner_must_transfer() from None
    except OutstandingBalance as e:
        raise _outstanding_balance(e) from None


@router.post("/{trip_id}/members/{user_id}/owner", response_model=list[MemberPublic])
async def transfer_ownership(trip_id: UUID, user_id: UUID, db: DbSession, owner: Ownership):
    """Make another member the owner; the caller becomes a plain member.

    Returns the members with their new roles, so the client never has to guess
    what changed.
    """
    try:
        target = await trip_service.get_membership(db, trip_id, user_id)
    except NotAMember:
        raise _MEMBER_NOT_FOUND from None

    await trip_service.transfer_ownership(db, owner, target)
    return await _members(db, trip_id)


@router.post("/{trip_id}/invites", response_model=InvitePublic, status_code=status.HTTP_201_CREATED)
async def create_invite(trip_id: UUID, payload: InviteCreate, db: DbSession, owner: Ownership):
    return await trip_service.create_invite(
        db, trip_id, owner.user_id, payload.expires_in_hours, payload.max_uses
    )


@router.get("/{trip_id}/invites", response_model=list[InvitePublic])
async def list_invites(trip_id: UUID, db: DbSession, _: Ownership):
    return await trip_service.list_invites(db, trip_id)


@router.delete("/{trip_id}/invites/{invite_id}", status_code=status.HTTP_204_NO_CONTENT)
async def revoke_invite(trip_id: UUID, invite_id: UUID, db: DbSession, _: Ownership):
    try:
        await trip_service.revoke_invite(db, trip_id, invite_id)
    except InvalidInvite:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Invite not found") from None
