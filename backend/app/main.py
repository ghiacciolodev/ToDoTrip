"""FastAPI application entrypoint."""

import logging
from contextlib import asynccontextmanager

from fastapi import FastAPI
from sqlalchemy import text

from app.config import get_settings
from app.database import SessionLocal, engine
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
from app.services import notification_service

settings = get_settings()
_log = logging.getLogger(__name__)


@asynccontextmanager
async def lifespan(app: FastAPI):
    # Old notifications go at startup rather than from a scheduler: it is one
    # DELETE on an indexed column, and a cron container to run it would be more
    # moving parts than the problem is worth at this size. A failure here must
    # not stop the API from starting — nobody is blocked by stale rows.
    try:
        async with SessionLocal() as session:
            removed = await notification_service.purge(session)
        if removed:
            _log.info("purged %s expired notifications", removed)
    except Exception:  # noqa: BLE001
        _log.exception("notification purge failed at startup")

    yield
    # Close pooled connections cleanly on shutdown.
    await engine.dispose()


app = FastAPI(
    title="TodoTrip API",
    version="0.1.0",
    lifespan=lifespan,
)

# All routes are versioned from day one: /api/v2 can coexist with /api/v1 while
# older mobile builds, which cannot be force-updated, keep working.
app.include_router(auth.router, prefix="/api/v1")
app.include_router(trips.router, prefix="/api/v1")
app.include_router(items.router, prefix="/api/v1")
app.include_router(expenses.router, prefix="/api/v1")
app.include_router(checklists.router, prefix="/api/v1")
app.include_router(map.router, prefix="/api/v1")
app.include_router(events.router, prefix="/api/v1")
app.include_router(notifications.router, prefix="/api/v1")


@app.get("/health", tags=["system"])
async def health() -> dict[str, str]:
    """Liveness probe that also proves the database is reachable.

    A health check that only returns 200 hides the most common production
    failure, which is the API being up while the database is not.
    """
    async with engine.connect() as conn:
        await conn.execute(text("SELECT 1"))
    return {"status": "ok", "environment": settings.environment}
