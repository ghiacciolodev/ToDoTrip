"""HTTP layer for trips, membership and invites."""

from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.responses import PlainTextResponse

from app.core.events import Notify, close_trip, emit, kick
from app.core.rate_limit import throttle
from app.dependencies import CurrentUser, DbSession, Membership, Ownership
from app.models import NotificationKind
from app.schemas.auth import UserPublic
from app.schemas.trip import (
    InviteCreate,
    InvitePublic,
    JoinRequest,
    MemberPreview,
    MemberPublic,
    MemberSettings,
    TripCreate,
    TripDetail,
    TripPublic,
    TripSummary,
    TripUpdate,
)
from app.services import export_service, trip_service
from app.services.trip_service import (
    InvalidInvite,
    NoLongerOwner,
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


@router.get("", response_model=list[TripSummary])
async def list_trips(db: DbSession, user: CurrentUser, archived: bool = False):
    """Every trip the caller belongs to, with what the list screen draws.

    Member count, the first avatars, the caller's own balance and when the trip
    was last touched travel with it, so ten cards cost one request rather than
    twenty-one. Ordered by that last activity, most recent first.
    """
    return [
        TripSummary(
            **TripPublic.model_validate(row["trip"]).model_dump(),
            member_count=row["member_count"],
            member_preview=[MemberPreview(**m) for m in row["member_preview"]],
            my_balance_cents=row["my_balance_cents"],
            last_activity_at=row["last_activity_at"],
        )
        for row in await trip_service.list_trips_with_summary(db, user.id, archived=archived)
    ]


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
        joined = await trip_service.join_by_code(db, payload.code, user.id)
    except InvalidInvite:
        raise HTTPException(status.HTTP_400_BAD_REQUEST, "Invalid or expired invite") from None
    await emit(
        joined.id,
        "members.changed",
        actor_id=user.id,
        db=db,
        # The actor is the person arriving, so "everyone but the actor" is
        # exactly the group they are arriving into.
        notify=Notify(
            kind=NotificationKind.MEMBER_JOINED,
            entity_id=user.id,
            payload={"actor_name": user.display_name, "trip_name": joined.name},
        ),
    )
    return joined


@router.get("/{trip_id}", response_model=TripDetail)
async def get_trip(trip_id: UUID, db: DbSession, membership: Membership):
    """One trip, with the counts and the total its settings screen shows."""
    trip = await trip_service.get_trip(db, trip_id)
    return TripDetail(
        **TripPublic.model_validate(trip).model_dump(),
        **await trip_service.trip_details(db, trip),
    )


@router.get("/{trip_id}/export.csv", response_class=PlainTextResponse)
async def export_expenses(trip_id: UUID, db: DbSession, membership: Membership):
    """The ledger as a spreadsheet.

    Open to any member, not just the owner: everybody's own money is in it, and
    the file says nothing the app does not already show them.
    """
    trip = await trip_service.get_trip(db, trip_id)
    return PlainTextResponse(
        # The BOM is what makes Excel read it as UTF-8 instead of the local
        # code page, which is the difference between "Cena" and "CenaÃ ".
        content="﻿" + await export_service.expenses_csv(db, trip),
        media_type="text/csv; charset=utf-8",
        headers={"Content-Disposition": export_service.content_disposition(trip.name)},
    )


@router.patch("/{trip_id}", response_model=TripPublic)
async def update_trip(trip_id: UUID, payload: TripUpdate, db: DbSession, owner: Ownership):
    trip = await trip_service.get_trip(db, trip_id)
    # exclude_unset: a PATCH must not blank fields the client did not send.
    trip = await trip_service.update_trip(db, trip, payload.model_dump(exclude_unset=True))
    await emit(trip_id, "trip.changed", actor_id=owner.user_id)
    return trip


@router.delete("/{trip_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_trip(trip_id: UUID, db: DbSession, owner: Ownership):
    actor_id = owner.user_id
    await trip_service.delete_trip(db, await trip_service.get_trip(db, trip_id))
    # Tell everyone still on the screen, then hang up: there is nothing left to
    # listen to.
    await emit(trip_id, "trip.deleted", actor_id=actor_id)
    await close_trip(trip_id)


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
@router.get("/{trip_id}/members/me/settings", response_model=MemberSettings)
async def my_settings(membership: Membership):
    return MemberSettings(muted=membership.muted)


@router.patch("/{trip_id}/members/me/settings", response_model=MemberSettings)
async def update_my_settings(payload: MemberSettings, db: DbSession, membership: Membership):
    """Only ever the caller's own row.

    There is no path here that names another member: muting is a decision about
    your own phone, and the endpoint is shaped so it cannot be aimed at anyone
    else even by mistake.
    """
    updated = await trip_service.set_muted(db, membership, payload.muted)
    return MemberSettings(muted=updated.muted)


@router.delete("/{trip_id}/members/me", status_code=status.HTTP_204_NO_CONTENT)
async def leave_trip(db: DbSession, membership: Membership):
    """Leave a trip, or delete it when leaving would empty it.

    An owner must hand the trip over first, and nobody may leave with an open
    balance: both are answered with a 409 carrying a code, because the app shows
    a different way forward for each.
    """
    # Captured before the service call: on success the membership row is gone,
    # and on trip deletion the trip is too.
    trip_id = membership.trip_id
    actor_id = membership.user_id
    try:
        deleted = await trip_service.leave_trip(db, membership)
    except OwnerMustTransfer:
        raise _owner_must_transfer() from None
    except OutstandingBalance as e:
        raise _outstanding_balance(e) from None

    if deleted:
        await emit(trip_id, "trip.deleted", actor_id=actor_id)
        await close_trip(trip_id)
    else:
        await emit(trip_id, "members.changed", actor_id=actor_id)
        # Their own sockets stop hearing a trip they no longer belong to.
        await kick(trip_id, actor_id)


@router.delete("/{trip_id}/members/{user_id}", status_code=status.HTTP_204_NO_CONTENT)
async def remove_member(trip_id: UUID, user_id: UUID, db: DbSession, owner: Ownership):
    """Remove someone else from the trip. Owner only."""
    try:
        target = await trip_service.get_membership(db, trip_id, user_id)
    except NotAMember:
        raise _MEMBER_NOT_FOUND from None

    actor_id = owner.user_id
    try:
        await trip_service.remove_by_owner(db, owner, target)
    except OwnerMustTransfer:
        raise _owner_must_transfer() from None
    except OutstandingBalance as e:
        raise _outstanding_balance(e) from None

    await emit(trip_id, "members.changed", actor_id=actor_id)
    # Cut the removed member's sockets: no data travels on this channel, but
    # even the bell is a signal of activity they are no longer entitled to.
    await kick(trip_id, user_id)


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

    actor_id = owner.user_id
    try:
        await trip_service.transfer_ownership(db, owner, target)
    except NoLongerOwner:
        # Two transfers were in flight and the other one landed first. The
        # caller is a plain member now, so this is not a permission problem to
        # retry against — the trip already has the owner it was given.
        raise _conflict(
            "no_longer_owner",
            "Somebody else handed this trip on first.",
        ) from None
    await emit(trip_id, "members.changed", actor_id=actor_id)
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
