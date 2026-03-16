"""Notes CRUD API routes."""

import uuid
from datetime import UTC, datetime
##if AUTH
from typing import Annotated
##endif

##if AUTH
from fastapi import APIRouter, Depends, HTTPException, status
##else
from fastapi import APIRouter, HTTPException, status
##endif

##if AUTH
from {{name}}.auth import get_current_user
##endif
from {{name}}.database import decode_tags, encode_tags, execute, fetch_all, fetch_one
from {{name}}.models import (
    CreateNoteRequest,
    NoteResponse,
    UpdateNoteRequest,
##if AUTH
    User,
##endif
)

router = APIRouter(prefix="/api/notes", tags=["notes"])


def _note_response(row: dict[str, object]) -> NoteResponse:
    return NoteResponse(
        id=str(row["id"]),
        title=str(row["title"]),
        content=str(row["content"]),
        tags=decode_tags(str(row["tags"])),
        created_at=datetime.fromisoformat(str(row["created_at"])),
        updated_at=datetime.fromisoformat(str(row["updated_at"])),
    )


@router.get("", response_model=list[NoteResponse])
##if AUTH
async def list_notes(
    user: Annotated[User, Depends(get_current_user)],
) -> list[NoteResponse]:
    """List all notes for the current user."""
    rows = await fetch_all(
        "SELECT * FROM notes WHERE user_id = ? ORDER BY updated_at DESC",
        (user.id,),
    )
##else
async def list_notes() -> list[NoteResponse]:
    """List all notes."""
    rows = await fetch_all(
        "SELECT * FROM notes ORDER BY updated_at DESC",
    )
##endif
    return [_note_response(r) for r in rows]


@router.post("", response_model=NoteResponse, status_code=201)
##if AUTH
async def create_note(
    body: CreateNoteRequest,
    user: Annotated[User, Depends(get_current_user)],
) -> NoteResponse:
##else
async def create_note(
    body: CreateNoteRequest,
) -> NoteResponse:
##endif
    """Create a new note."""
    now = datetime.now(UTC).isoformat()
    note_id = str(uuid.uuid4())

##if AUTH
    await execute(
        "INSERT INTO notes "
        "(id, user_id, title, content, tags, created_at, updated_at)"
        " VALUES (?, ?, ?, ?, ?, ?, ?)",
        (
            note_id,
            user.id,
            body.title,
            body.content,
            encode_tags(body.tags),
            now,
            now,
        ),
    )
##else
    await execute(
        "INSERT INTO notes "
        "(id, title, content, tags, created_at, updated_at)"
        " VALUES (?, ?, ?, ?, ?, ?)",
        (
            note_id,
            body.title,
            body.content,
            encode_tags(body.tags),
            now,
            now,
        ),
    )
##endif

    row = await fetch_one(
        "SELECT * FROM notes WHERE id = ?", (note_id,)
    )
    if row is None:  # pragma: no cover
        raise HTTPException(status_code=500, detail="Insert failed")
    return _note_response(row)


@router.get("/{note_id}", response_model=NoteResponse)
##if AUTH
async def get_note(
    note_id: str,
    user: Annotated[User, Depends(get_current_user)],
) -> NoteResponse:
    """Get a single note by ID."""
    row = await fetch_one(
        "SELECT * FROM notes WHERE id = ? AND user_id = ?",
        (note_id, user.id),
    )
##else
async def get_note(
    note_id: str,
) -> NoteResponse:
    """Get a single note by ID."""
    row = await fetch_one(
        "SELECT * FROM notes WHERE id = ?",
        (note_id,),
    )
##endif
    if row is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Note not found",
        )
    return _note_response(row)


@router.patch("/{note_id}", response_model=NoteResponse)
##if AUTH
async def update_note(
    note_id: str,
    body: UpdateNoteRequest,
    user: Annotated[User, Depends(get_current_user)],
) -> NoteResponse:
    """Update an existing note."""
    # Verify ownership
    existing = await fetch_one(
        "SELECT * FROM notes WHERE id = ? AND user_id = ?",
        (note_id, user.id),
    )
##else
async def update_note(
    note_id: str,
    body: UpdateNoteRequest,
) -> NoteResponse:
    """Update an existing note."""
    existing = await fetch_one(
        "SELECT * FROM notes WHERE id = ?",
        (note_id,),
    )
##endif
    if existing is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Note not found",
        )

    updates: list[str] = []
    params: list[object] = []

    if body.title is not None:
        updates.append("title = ?")
        params.append(body.title)
    if body.content is not None:
        updates.append("content = ?")
        params.append(body.content)
    if body.tags is not None:
        updates.append("tags = ?")
        params.append(encode_tags(body.tags))

    if updates:
        updates.append("updated_at = ?")
        params.append(datetime.now(UTC).isoformat())
        params.append(note_id)

        sql = f"UPDATE notes SET {', '.join(updates)} WHERE id = ?"  # noqa: S608
        await execute(sql, tuple(params))

    row = await fetch_one(
        "SELECT * FROM notes WHERE id = ?", (note_id,)
    )
    if row is None:  # pragma: no cover
        raise HTTPException(status_code=500, detail="Update failed")
    return _note_response(row)


@router.delete("/{note_id}", status_code=204)
##if AUTH
async def delete_note(
    note_id: str,
    user: Annotated[User, Depends(get_current_user)],
) -> None:
    """Delete a note."""
    existing = await fetch_one(
        "SELECT id FROM notes WHERE id = ? AND user_id = ?",
        (note_id, user.id),
    )
##else
async def delete_note(
    note_id: str,
) -> None:
    """Delete a note."""
    existing = await fetch_one(
        "SELECT id FROM notes WHERE id = ?",
        (note_id,),
    )
##endif
    if existing is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Note not found",
        )

    await execute("DELETE FROM notes WHERE id = ?", (note_id,))
