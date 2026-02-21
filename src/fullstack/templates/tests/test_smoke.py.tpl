"""Smoke tests for {{title}} API."""

import pytest
from httpx import ASGITransport, AsyncClient

from {{name}}.database import close_db, init_db
from {{name}}.main import app


@pytest.fixture(autouse=True)
async def _setup_db(tmp_path, monkeypatch):
    """Init an in-memory test database for each test."""
    import {{name}}.database as db_mod

    monkeypatch.setattr(db_mod, "_DB_PATH", tmp_path / "test.db")
    monkeypatch.setattr(db_mod, "_db", None)
    await init_db()
    yield
    await close_db()


@pytest.fixture
async def client():
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as c:
        yield c


async def test_health(client: AsyncClient):
    res = await client.get("/api/health")
    assert res.status_code == 200
    assert res.json() == {"status": "ok"}


async def test_register_and_login(client: AsyncClient):
    # Register
    res = await client.post(
        "/api/auth/register",
        json={"email": "test@example.com", "password": "testpass123"},
    )
    assert res.status_code == 201
    data = res.json()
    assert "token" in data
    assert data["user"]["email"] == "test@example.com"

    # Login with same credentials
    res = await client.post(
        "/api/auth/login",
        json={"email": "test@example.com", "password": "testpass123"},
    )
    assert res.status_code == 200
    assert "token" in res.json()


async def test_notes_crud(client: AsyncClient):
    # Register to get a token
    res = await client.post(
        "/api/auth/register",
        json={"email": "notes@example.com", "password": "testpass123"},
    )
    token = res.json()["token"]
    headers = {"Authorization": f"Bearer {token}"}

    # Create a note
    res = await client.post(
        "/api/notes",
        json={"title": "Test Note", "content": "Hello world", "tags": ["test"]},
        headers=headers,
    )
    assert res.status_code == 201
    note = res.json()
    assert note["title"] == "Test Note"
    note_id = note["id"]

    # List notes
    res = await client.get("/api/notes", headers=headers)
    assert res.status_code == 200
    assert len(res.json()) == 1

    # Update the note
    res = await client.patch(
        f"/api/notes/{note_id}",
        json={"title": "Updated Note"},
        headers=headers,
    )
    assert res.status_code == 200
    assert res.json()["title"] == "Updated Note"

    # Delete the note
    res = await client.delete(f"/api/notes/{note_id}", headers=headers)
    assert res.status_code == 204

    # Verify deletion
    res = await client.get("/api/notes", headers=headers)
    assert res.status_code == 200
    assert len(res.json()) == 0
