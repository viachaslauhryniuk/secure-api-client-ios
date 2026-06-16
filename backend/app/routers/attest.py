import base64
import secrets

from fastapi import APIRouter, HTTPException, status

from ..data import ATTEST_CHALLENGES, ATTESTED_KEYS
from ..models import (
    AssertRequest,
    ChallengeResponse,
    MessageResponse,
    RegisterKeyRequest,
)
from ..security import verify_p256_signature

router = APIRouter(prefix="/attest", tags=["attest"])


def _consume_challenge(challenge: str) -> None:
    if challenge not in ATTEST_CHALLENGES:
        raise HTTPException(status.HTTP_401_UNAUTHORIZED, "unknown or already-used challenge")
    ATTEST_CHALLENGES.discard(challenge)


@router.post("/challenge", response_model=ChallengeResponse)
def challenge() -> ChallengeResponse:
    nonce = secrets.token_urlsafe(32)
    ATTEST_CHALLENGES.add(nonce)
    return ChallengeResponse(challenge=nonce)


@router.post("/register", response_model=MessageResponse)
def register(body: RegisterKeyRequest) -> MessageResponse:
    _consume_challenge(body.challenge)
    sig = base64.b64decode(body.signature)
    if not verify_p256_signature(body.public_key_pem, body.challenge.encode(), sig):
        raise HTTPException(status.HTTP_401_UNAUTHORIZED, "attestation signature invalid")
    ATTESTED_KEYS[body.key_id] = body.public_key_pem
    return MessageResponse(message="key attested")


@router.post("/assert", response_model=MessageResponse)
def assert_request(body: AssertRequest) -> MessageResponse:
    public_key_pem = ATTESTED_KEYS.get(body.key_id)
    if public_key_pem is None:
        raise HTTPException(status.HTTP_401_UNAUTHORIZED, "unknown key_id (not attested)")
    _consume_challenge(body.challenge)
    sig = base64.b64decode(body.signature)
    if not verify_p256_signature(public_key_pem, body.challenge.encode(), sig):
        raise HTTPException(status.HTTP_401_UNAUTHORIZED, "assertion signature invalid")
    return MessageResponse(message="assertion verified")
