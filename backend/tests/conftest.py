"""Shared test fixtures.

Tests run against a dedicated database (todotrip_test) that is dropped and
recreated per session, so they never depend on, or damage, development data.
"""

import os
from collections.abc import AsyncGenerator

import pytest
from httpx import ASGITransport, AsyncClient
from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker, create_async_engine
from sqlalchemy.pool import NullPool

from app.database import get_db
from app.main import app
from app.models import Base

TEST_DATABASE_URL = os.getenv(
    "TEST_DATABASE_URL",
    "postgresql+asyncpg://todotrip:todotrip@localhost:5432/todotrip_test",
)

# NullPool: no connection is kept alive between tests, which avoids reusing a
# connection across event loops.
test_engine = create_async_engine(TEST_DATABASE_URL, poolclass=NullPool)
TestSession = async_sessionmaker(test_engine, class_=AsyncSession, expire_on_commit=False)


@pytest.fixture(scope="session", autouse=True)
async def _schema() -> AsyncGenerator[None]:
    """Build the schema once from the models.

    create_all is used instead of Alembic because it is much faster; the
    migrations themselves are exercised separately in CI.
    """
    async with test_engine.begin() as conn:
        await conn.run_sync(Base.metadata.drop_all)
        await conn.run_sync(Base.metadata.create_all)
    yield
    await test_engine.dispose()


@pytest.fixture(autouse=True)
async def _clean_tables() -> AsyncGenerator[None]:
    """Empty every table after each test so tests stay order-independent."""
    yield
    tables = ", ".join(Base.metadata.tables)
    async with test_engine.begin() as conn:
        await conn.execute(text(f"TRUNCATE TABLE {tables} RESTART IDENTITY CASCADE"))


@pytest.fixture
async def db() -> AsyncGenerator[AsyncSession]:
    """Direct database access, for asserting on stored state."""
    async with TestSession() as session:
        yield session


@pytest.fixture
async def client() -> AsyncGenerator[AsyncClient]:
    """HTTP client wired to the app, with the test database injected.

    dependency_overrides replaces get_db without touching application code:
    the app under test is the real one, only its database differs.
    """

    async def _override_get_db() -> AsyncGenerator[AsyncSession]:
        async with TestSession() as session:
            yield session

    app.dependency_overrides[get_db] = _override_get_db
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as ac:
        yield ac
    app.dependency_overrides.clear()


# Reused across tests so credentials live in exactly one place.
USER = {"email": "mario@test.it", "password": "password123", "display_name": "Mario"}


@pytest.fixture
async def registered_user(client: AsyncClient) -> dict:
    await client.post("/api/v1/auth/register", json=USER)
    return USER


@pytest.fixture
async def tokens(client: AsyncClient, registered_user: dict) -> dict:
    response = await client.post(
        "/api/v1/auth/login",
        json={"email": registered_user["email"], "password": registered_user["password"]},
    )
    return response.json()


@pytest.fixture
def auth_headers(tokens: dict) -> dict[str, str]:
    return {"Authorization": f"Bearer {tokens['access_token']}"}
