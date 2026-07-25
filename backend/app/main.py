"""FastAPI application entrypoint."""

from contextlib import asynccontextmanager

from fastapi import FastAPI
from sqlalchemy import text

from app.config import get_settings
from app.database import engine
from app.routers import auth, trips

settings = get_settings()


@asynccontextmanager
async def lifespan(app: FastAPI):
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


@app.get("/health", tags=["system"])
async def health() -> dict[str, str]:
    """Liveness probe that also proves the database is reachable.

    A health check that only returns 200 hides the most common production
    failure, which is the API being up while the database is not.
    """
    async with engine.connect() as conn:
        await conn.execute(text("SELECT 1"))
    return {"status": "ok", "environment": settings.environment}
