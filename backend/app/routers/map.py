"""HTTP layer for the shared map: member locations and pins.

Two features that share a screen and nothing else. Pins are durable group data;
locations are ephemeral, self-reported and deleted the moment sharing stops —
one can be on while the other is off.
"""

from uuid import UUID

from fastapi import APIRouter, HTTPException, status

from app.core.events import emit
from app.dependencies import CurrentUser, DbSession, Membership
from app.schemas.map import LocationPublic, LocationUpdate, PinCreate, PinPublic, PinUpdate
from app.services import map_service
from app.services.map_service import PinNotFound

# The trip_id in the prefix feeds the Membership dependency, so every route
# below is authorized before its body runs.
router = APIRouter(prefix="/trips/{trip_id}", tags=["map"])

_PIN_NOT_FOUND = HTTPException(status.HTTP_404_NOT_FOUND, "Pin not found")


@router.put("/location", response_model=LocationPublic)
async def update_location(
    trip_id: UUID, payload: LocationUpdate, db: DbSession, user: CurrentUser, _: Membership
):
    """Report where the caller is. Always themselves: the id comes from the
    token, so nobody can place someone else on the map."""
    location = await map_service.upsert_location(db, trip_id, user.id, payload.model_dump())
    # Carries its data: see the note in events.emit about why positions are the
    # one thing pushed rather than announced.
    await emit(
        trip_id,
        "location.update",
        actor_id=user.id,
        data={
            "user_id": str(user.id),
            "lat": location.latitude,
            "lng": location.longitude,
            "accuracy_m": location.accuracy_m,
            "at": location.updated_at.isoformat(),
        },
    )
    return location


@router.delete("/location", status_code=status.HTTP_204_NO_CONTENT)
async def clear_location(trip_id: UUID, db: DbSession, user: CurrentUser, _: Membership):
    await map_service.clear_location(db, trip_id, user.id)
    await emit(trip_id, "location.cleared", actor_id=user.id, data={"user_id": str(user.id)})


@router.get("/locations", response_model=list[LocationPublic])
async def list_locations(trip_id: UUID, db: DbSession, _: Membership):
    """Who is currently sharing, expired rows excluded."""
    return await map_service.list_locations(db, trip_id)


@router.get("/pins", response_model=list[PinPublic])
async def list_pins(trip_id: UUID, db: DbSession, _: Membership):
    return await map_service.list_pins(db, trip_id)


@router.post("/pins", response_model=PinPublic, status_code=status.HTTP_201_CREATED)
async def create_pin(
    trip_id: UUID, payload: PinCreate, db: DbSession, user: CurrentUser, _: Membership
):
    pin = await map_service.create_pin(db, trip_id, user.id, payload.model_dump())
    await emit(trip_id, "pins.changed", actor_id=user.id)
    return pin


@router.patch("/pins/{pin_id}", response_model=PinPublic)
async def update_pin(
    trip_id: UUID, pin_id: UUID, payload: PinUpdate, db: DbSession, membership: Membership
):
    try:
        pin = await map_service.get_pin(db, trip_id, pin_id)
        # exclude_unset: a PATCH must not blank fields the client did not send.
        pin = await map_service.update_pin(db, pin, payload.model_dump(exclude_unset=True))
    except PinNotFound:
        raise _PIN_NOT_FOUND from None
    await emit(trip_id, "pins.changed", actor_id=membership.user_id)
    return pin


@router.delete("/pins/{pin_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_pin(trip_id: UUID, pin_id: UUID, db: DbSession, membership: Membership):
    """Any member can delete, as for expenses and tasks: a shared map nobody is
    allowed to tidy stops being useful."""
    try:
        await map_service.delete_pin(db, await map_service.get_pin(db, trip_id, pin_id))
    except PinNotFound:
        raise _PIN_NOT_FOUND from None
    await emit(trip_id, "pins.changed", actor_id=membership.user_id)
