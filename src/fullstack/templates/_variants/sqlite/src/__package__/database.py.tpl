"""Async SQLite database with WAL mode and lazy-init singleton."""

import json
from pathlib import Path
from typing import Any

import aiosqlite

_DB_PATH = Path("data/{{name}}.db")
_db: aiosqlite.Connection | None = None

SCHEMA = """
##if AUTH
CREATE TABLE IF NOT EXISTS users (
    id TEXT PRIMARY KEY,
    email TEXT UNIQUE NOT NULL,
    hashed_password TEXT NOT NULL,
    created_at TEXT NOT NULL
);

##endif
CREATE TABLE IF NOT EXISTS notes (
    id TEXT PRIMARY KEY,
##if AUTH
    user_id TEXT NOT NULL REFERENCES users(id),
##endif
    title TEXT NOT NULL DEFAULT '',
    content TEXT NOT NULL DEFAULT '',
    tags TEXT NOT NULL DEFAULT '[]',
    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL
);
##if AUTH

CREATE INDEX IF NOT EXISTS idx_notes_user_id ON notes(user_id);
##endif
"""


async def get_db() -> aiosqlite.Connection:
    """Return the singleton database connection."""
    global _db  # noqa: PLW0603
    if _db is None:
        _DB_PATH.parent.mkdir(parents=True, exist_ok=True)
        _db = await aiosqlite.connect(str(_DB_PATH))
        _db.row_factory = aiosqlite.Row
        await _db.execute("PRAGMA journal_mode=WAL")
        await _db.execute("PRAGMA foreign_keys=ON")
    return _db


async def init_db() -> None:
    """Create tables if they don't exist."""
    db = await get_db()
    await db.executescript(SCHEMA)
    await db.commit()


async def close_db() -> None:
    """Close the database connection."""
    global _db  # noqa: PLW0603
    if _db is not None:
        await _db.close()
        _db = None


async def fetch_one(
    sql: str, params: tuple[Any, ...] = ()
) -> dict[str, Any] | None:
    """Execute a query and return the first row as a dict, or None."""
    db = await get_db()
    cursor = await db.execute(sql, params)
    row = await cursor.fetchone()
    return dict(row) if row is not None else None


async def fetch_all(
    sql: str, params: tuple[Any, ...] = ()
) -> list[dict[str, Any]]:
    """Execute a query and return all rows as dicts."""
    db = await get_db()
    cursor = await db.execute(sql, params)
    rows = await cursor.fetchall()
    return [dict(r) for r in rows]


async def execute(sql: str, params: tuple[Any, ...] = ()) -> None:
    """Execute a write query and commit."""
    db = await get_db()
    await db.execute(sql, params)
    await db.commit()


def encode_tags(tags: list[str]) -> str:
    """Encode a list of tags as JSON text for storage."""
    return json.dumps(tags)


def decode_tags(text: str) -> list[str]:
    """Decode JSON text back to a list of tags."""
    result: list[str] = json.loads(text)
    return result
