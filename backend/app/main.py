"""FastAPI application entrypoint."""

import asyncio
from contextlib import asynccontextmanager, suppress

from fastapi import FastAPI
from sqlalchemy import text

from app.config import get_settings
from app.core import housekeeping, observability
from app.database import engine
from app.dependencies import ThrottledWrite
from app.routers import (
    auth,
    checklists,
    events,
    expenses,
    items,
    map,
    notifications,
    trips,
)

settings = get_settings()

# Before anything else, so that whatever the import of a router or the first
# database connection has to say is written in the configured format.
observability.configure_logging(
    level=settings.log_level,
    human_readable=settings.environment == "development",
)


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Starts the background sweep and stops it cleanly on shutdown.

    Cancelled rather than left to die with the process, so a reload during
    development does not leave a second loop running against the same database.
    """
    housekeeper = None
    if settings.notification_purge_hours > 0:
        housekeeper = asyncio.create_task(
            housekeeping.purge_notifications_forever(settings.notification_purge_hours * 3600)
        )

    yield

    if housekeeper is not None:
        housekeeper.cancel()
        with suppress(asyncio.CancelledError):
            await housekeeper
    # Close pooled connections cleanly on shutdown.
    await engine.dispose()


app = FastAPI(
    title="TodoTrip API",
    version="0.1.0",
    lifespan=lifespan,
)

# One line per request, carrying an id that is also returned in X-Request-ID so
# somebody reporting a failure has something to quote.
app.add_middleware(observability.RequestLogMiddleware)

# All routes are versioned from day one: /api/v2 can coexist with /api/v1 while
# older mobile builds, which cannot be force-updated, keep working.
#
# Everything a signed-in caller can write is throttled per account. Attaching it
# here rather than to each endpoint means an endpoint added next year is covered
# without anybody remembering to. The auth router keeps its own address-keyed
# limits: there is no account yet to count against.
_signed_in = [ThrottledWrite]

app.include_router(auth.router, prefix="/api/v1")
app.include_router(trips.router, prefix="/api/v1", dependencies=_signed_in)
app.include_router(items.router, prefix="/api/v1", dependencies=_signed_in)
app.include_router(expenses.router, prefix="/api/v1", dependencies=_signed_in)
app.include_router(checklists.router, prefix="/api/v1", dependencies=_signed_in)
app.include_router(map.router, prefix="/api/v1", dependencies=_signed_in)
# The websocket router is left out: it authenticates in its first frame, not
# through the HTTP dependency, and it is one connection rather than a stream of
# requests.
app.include_router(events.router, prefix="/api/v1")
app.include_router(notifications.router, prefix="/api/v1", dependencies=_signed_in)


@app.get("/health", tags=["system"])
async def health() -> dict[str, str]:
    """Liveness probe that also proves the database is reachable.

    A health check that only returns 200 hides the most common production
    failure, which is the API being up while the database is not.
    """
    async with engine.connect() as conn:
        await conn.execute(text("SELECT 1"))
    return {"status": "ok", "environment": settings.environment}
