"""Shared test fixtures for {{title}}."""

import os

import pytest
from httpx import ASGITransport, AsyncClient

from {{name}}.database import close_db, init_db
from {{name}}.main import app


@pytest.fixture(autouse=True)
async def _setup_db(monkeypatch):
    """Init the test database and truncate tables between tests."""
    import {{name}}.database as db_mod

    test_url = os.environ.get(
        "TEST_DATABASE_URL", "postgresql://localhost/{{name}}_test"
    )
    monkeypatch.setattr(db_mod, "DATABASE_URL", test_url)
    monkeypatch.setattr(db_mod, "_pool", None)

    await init_db()
    yield
    # Truncate all tables between tests
    pool = await db_mod.get_pool()
    async with pool.acquire() as conn:
        await conn.execute("TRUNCATE notes CASCADE")
##if AUTH
        await conn.execute("TRUNCATE users CASCADE")
##endif
    await close_db()


@pytest.fixture
async def client():
    """Async HTTP client wired to the FastAPI app."""
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as c:
        yield c


##if AUTH
@pytest.fixture
async def auth_headers(client: AsyncClient) -> dict[str, str]:
    """Register a test user and return auth headers."""
    res = await client.post(
        "/api/auth/register",
        json={"email": "test@example.com", "password": "testpass123"},
    )
    token = res.json()["token"]
    return {"Authorization": f"Bearer {token}"}
##endif
