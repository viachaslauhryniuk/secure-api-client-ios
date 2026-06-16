from __future__ import annotations

from pydantic import BaseModel, Field


class LoginRequest(BaseModel):
    username: str = Field(..., examples=["demo"])
    password: str = Field(..., examples=["Password123!"])


class TokenResponse(BaseModel):
    token_type: str = "Bearer"
    access_token: str
    expires_in: int
    refresh_token: str
    scope: str


class RefreshRequest(BaseModel):
    refresh_token: str


class LogoutRequest(BaseModel):
    refresh_token: str


class MessageResponse(BaseModel):
    message: str


class Account(BaseModel):
    id: str
    type: str
    nickname: str
    iban_masked: str
    currency: str
    available_balance: float
    ledger_balance: float


class SessionInfo(BaseModel):
    issued_at: str
    expires_at: str
    scope: str
    device_bound: bool


class ProfileResponse(BaseModel):
    user_id: str
    username: str
    full_name: str
    email_masked: str
    phone_masked: str
    kyc_status: str
    account_status: str
    two_factor_enabled: bool
    created_at: str
    last_login_at: str
    accounts: list[Account]
    session: SessionInfo


class ChallengeResponse(BaseModel):
    challenge: str


class RegisterKeyRequest(BaseModel):
    key_id: str
    public_key_pem: str
    challenge: str
    signature: str


class AssertRequest(BaseModel):
    key_id: str
    challenge: str
    signature: str
