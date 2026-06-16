import secrets
from datetime import datetime, timezone

from fastapi import APIRouter, HTTPException, status

from ..config import settings
from ..data import (
    DUMMY_PASSWORD_HASH,
    REFRESH_TOKENS,
    get_user_by_username,
)
from ..models import (
    LoginRequest,
    LogoutRequest,
    MessageResponse,
    RefreshRequest,
    TokenResponse,
)
from ..security import create_access_token, verify_password

router = APIRouter(tags=["auth"])


def _issue_refresh_token(user_id: str) -> str:
    token = secrets.token_urlsafe(48)
    REFRESH_TOKENS[token] = {
        "user_id": user_id,
        "expires_at": datetime.now(timezone.utc) + settings.refresh_token_ttl,
    }
    return token


def _token_pair(user_id: str) -> TokenResponse:
    return TokenResponse(
        access_token=create_access_token(user_id, settings.default_scope),
        expires_in=int(settings.access_token_ttl.total_seconds()),
        refresh_token=_issue_refresh_token(user_id),
        scope=settings.default_scope,
    )


@router.post("/login", response_model=TokenResponse)
def login(body: LoginRequest) -> TokenResponse:
    user = get_user_by_username(body.username)
    if user is None:
        verify_password(body.password, DUMMY_PASSWORD_HASH)
        raise HTTPException(status.HTTP_401_UNAUTHORIZED, "invalid credentials")
    if not verify_password(body.password, user["password_hash"]):
        raise HTTPException(status.HTTP_401_UNAUTHORIZED, "invalid credentials")

    user["last_login_at"] = datetime.now(timezone.utc).isoformat()
    return _token_pair(user["user_id"])


@router.post("/auth/refresh", response_model=TokenResponse)
def refresh(body: RefreshRequest) -> TokenResponse:
    record = REFRESH_TOKENS.get(body.refresh_token)
    if record is None or record["expires_at"] < datetime.now(timezone.utc):
        raise HTTPException(status.HTTP_401_UNAUTHORIZED, "invalid or expired refresh token")
    REFRESH_TOKENS.pop(body.refresh_token, None)
    return _token_pair(record["user_id"])


@router.post("/logout", response_model=MessageResponse)
def logout(body: LogoutRequest) -> MessageResponse:
    existed = REFRESH_TOKENS.pop(body.refresh_token, None) is not None
    return MessageResponse(message="logged out" if existed else "already logged out")
