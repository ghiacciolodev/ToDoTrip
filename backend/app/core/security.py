"""Password hashing and JWT primitives. No database access lives here."""

import hashlib
import secrets
from datetime import UTC, datetime, timedelta
from uuid import UUID

import jwt
from argon2 import PasswordHasher
from argon2.exceptions import InvalidHashError, VerificationError, VerifyMismatchError

from app.config import get_settings

settings = get_settings()

# Argon2id with library defaults: memory-hard, so GPU cracking of a leaked
# database is orders of magnitude slower than with bcrypt.
_hasher = PasswordHasher()


def hash_password(password: str) -> str:
    return _hasher.hash(password)


def verify_password(password: str, password_hash: str) -> bool:
    try:
        _hasher.verify(password_hash, password)
        return True
    except (VerifyMismatchError, VerificationError, InvalidHashError):
        return False


def create_access_token(user_id: UUID) -> str:
    """Short-lived, stateless token. Never checked against the database."""
    now = datetime.now(UTC)
    payload = {
        "sub": str(user_id),
        "iat": now,
        "exp": now + timedelta(minutes=settings.access_token_minutes),
        # Prevents a refresh token from ever being accepted as an access token.
        "type": "access",
    }
    return jwt.encode(payload, settings.jwt_secret, algorithm=settings.jwt_algorithm)


def decode_access_token(token: str) -> UUID | None:
    """Return the user id, or None for any invalid, expired or malformed token."""
    try:
        payload = jwt.decode(token, settings.jwt_secret, algorithms=[settings.jwt_algorithm])
    except jwt.PyJWTError:
        return None
    if payload.get("type") != "access":
        return None
    try:
        return UUID(payload["sub"])
    except (KeyError, ValueError, TypeError):
        return None


def generate_refresh_token() -> tuple[str, str]:
    """Return (raw token for the client, hash to store)."""
    raw = secrets.token_urlsafe(48)
    return raw, hash_refresh_token(raw)


def hash_refresh_token(raw: str) -> str:
    # SHA-256 is enough here, unlike for passwords: the token is 48 bytes of
    # cryptographic randomness, so there is nothing to brute-force. Argon2 would
    # only add latency to every refresh call.
    return hashlib.sha256(raw.encode()).hexdigest()
