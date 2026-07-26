"""HTTP layer for authentication. Translates service errors into status codes."""

from fastapi import APIRouter, Depends, HTTPException, status

from app.core import security
from app.core.rate_limit import throttle
from app.dependencies import CurrentUser, DbSession
from app.schemas.auth import (
    RefreshRequest,
    TokenPair,
    UserLogin,
    UserPublic,
    UserRegister,
)
from app.services import auth_service
from app.services.auth_service import AuthError, EmailAlreadyUsed

router = APIRouter(prefix="/auth", tags=["auth"])

# Password verification is intentionally slow (Argon2), which makes these two
# endpoints both the way in for a brute force and a cheap way to exhaust the
# server. The limits are loose enough that a person mistyping a password never
# meets them.
_login_throttle = Depends(throttle(limit=10, window_seconds=300, scope="login"))
_register_throttle = Depends(throttle(limit=5, window_seconds=3600, scope="register"))
# Refresh runs on every cold start of the app, so it is limited only against
# obvious abuse.
_refresh_throttle = Depends(throttle(limit=60, window_seconds=3600, scope="refresh"))

# Same message for every failure mode, so responses never reveal which emails
# are registered.
_INVALID_CREDENTIALS = HTTPException(
    status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid credentials"
)


@router.post(
    "/register",
    response_model=UserPublic,
    status_code=status.HTTP_201_CREATED,
    dependencies=[_register_throttle],
)
async def register(payload: UserRegister, db: DbSession):
    try:
        return await auth_service.register(
            db, payload.email, payload.password, payload.display_name
        )
    except EmailAlreadyUsed:
        # `from None` drops the internal exception from the traceback: the
        # client gets a clean 409, not a chained stack trace.
        raise HTTPException(status.HTTP_409_CONFLICT, "Email already registered") from None


@router.post("/login", response_model=TokenPair, dependencies=[_login_throttle])
async def login(payload: UserLogin, db: DbSession):
    try:
        user = await auth_service.authenticate(db, payload.email, payload.password)
    except AuthError:
        raise _INVALID_CREDENTIALS from None
    return TokenPair(
        access_token=security.create_access_token(user.id),
        refresh_token=await auth_service.issue_refresh_token(db, user.id),
    )


@router.post("/refresh", response_model=TokenPair, dependencies=[_refresh_throttle])
async def refresh(payload: RefreshRequest, db: DbSession):
    try:
        user, new_refresh = await auth_service.rotate_refresh_token(db, payload.refresh_token)
    except AuthError:
        raise _INVALID_CREDENTIALS from None
    return TokenPair(
        access_token=security.create_access_token(user.id),
        refresh_token=new_refresh,
    )


@router.post("/logout", status_code=status.HTTP_204_NO_CONTENT)
async def logout(payload: RefreshRequest, db: DbSession):
    await auth_service.revoke_refresh_token(db, payload.refresh_token)


@router.get("/me", response_model=UserPublic)
async def me(user: CurrentUser):
    return user
