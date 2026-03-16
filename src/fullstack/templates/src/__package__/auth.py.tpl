"""Authentication utilities: password hashing, JWT, and FastAPI dependency."""

import os
import uuid
from datetime import UTC, datetime, timedelta
from typing import Annotated

import bcrypt as _bcrypt
import jwt
from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer

from {{name}}.database import execute, fetch_one
from {{name}}.models import User

SECRET_KEY = os.environ.get("JWT_SECRET", "dev-secret-change-me")
ALGORITHM = "HS256"
TOKEN_EXPIRY_HOURS = 72

_bearer = HTTPBearer()


def hash_password(password: str) -> str:
    """Hash a password with bcrypt."""
    return _bcrypt.hashpw(password.encode(), _bcrypt.gensalt()).decode()


def verify_password(password: str, hashed: str) -> bool:
    """Verify a password against its bcrypt hash."""
    return _bcrypt.checkpw(password.encode(), hashed.encode())


def create_token(user_id: str) -> str:
    """Create a JWT token for the given user ID."""
    payload = {
        "sub": user_id,
        "exp": datetime.now(UTC) + timedelta(hours=TOKEN_EXPIRY_HOURS),
        "iat": datetime.now(UTC),
    }
    return jwt.encode(payload, SECRET_KEY, algorithm=ALGORITHM)


def decode_token(token: str) -> str:
    """Decode a JWT and return the user ID.

    Raises:
        HTTPException: If the token is invalid or expired.
    """
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        user_id: str | None = payload.get("sub")
        if user_id is None:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid token",
            )
        return user_id
    except jwt.ExpiredSignatureError:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Token expired",
        ) from None
    except jwt.InvalidTokenError:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid token",
        ) from None


async def get_current_user(
    credentials: Annotated[HTTPAuthorizationCredentials, Depends(_bearer)],
) -> User:
    """FastAPI dependency that extracts and validates the current user."""
    user_id = decode_token(credentials.credentials)
    row = await fetch_one(
        "SELECT * FROM users WHERE id = ?", (user_id,)
    )
    if row is None:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="User not found",
        )
    return User(**row)


async def register_user(email: str, password: str) -> User:
    """Create a new user account.

    Raises:
        HTTPException: If the email is already registered.
    """
    existing = await fetch_one(
        "SELECT id FROM users WHERE email = ?", (email,)
    )
    if existing:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Email already registered",
        )

    user = User(
        id=str(uuid.uuid4()),
        email=email,
        hashed_password=hash_password(password),
        created_at=datetime.now(UTC),
    )

    await execute(
        "INSERT INTO users (id, email, hashed_password, created_at)"
        " VALUES (?, ?, ?, ?)",
        (
            user.id,
            user.email,
            user.hashed_password,
            user.created_at.isoformat(),
        ),
    )

    return user


async def authenticate_user(email: str, password: str) -> User:
    """Validate credentials and return the user.

    Raises:
        HTTPException: If credentials are invalid.
    """
    row = await fetch_one(
        "SELECT * FROM users WHERE email = ?", (email,)
    )
    if row is None:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid credentials",
        )

    user = User(**row)
    if not verify_password(password, user.hashed_password):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid credentials",
        )

    return user
