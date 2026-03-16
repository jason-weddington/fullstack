"""Async PostgreSQL database with connection pooling."""

import json
import os
import re
from typing import Any

import asyncpg

_pool: asyncpg.Pool | None = None

DATABASE_URL = os.environ.get(
    "DATABASE_URL", "postgresql://localhost/{{name}}"
)

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


def _convert_placeholders(sql: str) -> str:
    """Convert ? placeholders to $1, $2, ... for asyncpg."""
    counter = 0

    def _replace(_match: re.Match[str]) -> str:
        nonlocal counter
        counter += 1
        return f"${counter}"

    return re.sub(r"\?", _replace, sql)


async def get_pool() -> asyncpg.Pool:
    """Return the singleton connection pool."""
    global _pool  # noqa: PLW0603
    if _pool is None:
        _pool = await asyncpg.create_pool(DATABASE_URL)
    return _pool


async def init_db() -> None:
    """Create tables if they don't exist."""
    pool = await get_pool()
    async with pool.acquire() as conn:
        await conn.execute(SCHEMA)


async def close_db() -> None:
    """Close the connection pool."""
    global _pool  # noqa: PLW0603
    if _pool is not None:
        await _pool.close()
        _pool = None


async def fetch_one(
    sql: str, params: tuple[Any, ...] = ()
) -> dict[str, Any] | None:
    """Execute a query and return the first row as a dict, or None."""
    pool = await get_pool()
    async with pool.acquire() as conn:
        row = await conn.fetchrow(_convert_placeholders(sql), *params)
        return dict(row) if row is not None else None


async def fetch_all(
    sql: str, params: tuple[Any, ...] = ()
) -> list[dict[str, Any]]:
    """Execute a query and return all rows as dicts."""
    pool = await get_pool()
    async with pool.acquire() as conn:
        rows = await conn.fetch(_convert_placeholders(sql), *params)
        return [dict(r) for r in rows]


async def execute(sql: str, params: tuple[Any, ...] = ()) -> None:
    """Execute a write query."""
    pool = await get_pool()
    async with pool.acquire() as conn:
        await conn.execute(_convert_placeholders(sql), *params)


def encode_tags(tags: list[str]) -> str:
    """Encode a list of tags as JSON text for storage."""
    return json.dumps(tags)


def decode_tags(text: str) -> list[str]:
    """Decode JSON text back to a list of tags."""
    result: list[str] = json.loads(text)
    return result
