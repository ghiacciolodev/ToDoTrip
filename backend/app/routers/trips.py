"""HTTP layer for trips, membership and invites."""

from uuid import UUID

from fastapi import APIRouter, HTTPException, status

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
from app.services.trip_service import InvalidInvite, NotAnOwner

router = APIRouter(prefix="/trips", tags=["trips"])


@router.post("", response_model=TripPublic, status_code=status.HTTP_201_CREATED)
async def create_trip(payload: TripCreate, db: DbSession, user: CurrentUser):
    return await trip_service.create_trip(db, user.id, payload.model_dump())


@router.get("", response_model=list[TripPublic])
async def list_trips(db: DbSession, user: CurrentUser):
    return await trip_service.list_trips(db, user.id)


# Declared before the /{trip_id} routes so "join" is never parsed as an id.
@router.post("/join", response_model=TripPublic)
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
    rows = await trip_service.list_members(db, trip_id)
    return [
        MemberPublic(user=UserPublic.model_validate(user), role=m.role, joined_at=m.joined_at)
        for m, user in rows
    ]


@router.delete("/{trip_id}/members/me", status_code=status.HTTP_204_NO_CONTENT)
async def leave_trip(db: DbSession, membership: Membership):
    try:
        await trip_service.leave_trip(db, membership)
    except NotAnOwner:
        raise HTTPException(
            status.HTTP_409_CONFLICT, "The owner must delete the trip instead of leaving"
        ) from None


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
