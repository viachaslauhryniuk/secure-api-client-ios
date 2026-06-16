import base64
import hashlib
import hmac
import os
import uuid
from datetime import datetime, timezone

import jwt
from cryptography.exceptions import InvalidSignature
from cryptography.hazmat.primitives import hashes
from cryptography.hazmat.primitives.asymmetric import ec
from cryptography.hazmat.primitives.serialization import load_pem_public_key
from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer

from .config import settings

_PBKDF2_ITERATIONS = 200_000


def hash_password(password: str, salt: bytes | None = None) -> str:
    if salt is None:
        salt = os.urandom(16)
    dk = hashlib.pbkdf2_hmac("sha256", password.encode(), salt, _PBKDF2_ITERATIONS)
    return (
        f"pbkdf2_sha256${_PBKDF2_ITERATIONS}$"
        f"{base64.b64encode(salt).decode()}${base64.b64encode(dk).decode()}"
    )


def verify_password(password: str, encoded: str) -> bool:
    try:
        _, iterations, b64salt, b64hash = encoded.split("$")
        salt = base64.b64decode(b64salt)
        expected = base64.b64decode(b64hash)
        dk = hashlib.pbkdf2_hmac("sha256", password.encode(), salt, int(iterations))
    except Exception:
        return False
    return hmac.compare_digest(dk, expected)


def create_access_token(user_id: str, scope: str) -> str:
    now = datetime.now(timezone.utc)
    claims = {
        "sub": user_id,
        "iss": settings.jwt_issuer,
        "aud": settings.jwt_audience,
        "iat": now,
        "nbf": now,
        "exp": now + settings.access_token_ttl,
        "jti": uuid.uuid4().hex,
        "scope": scope,
        "token_use": "access",
    }
    return jwt.encode(claims, settings.jwt_secret, algorithm=settings.jwt_algorithm)


_bearer = HTTPBearer(auto_error=True)


def get_current_claims(creds: HTTPAuthorizationCredentials = Depends(_bearer)) -> dict:
    try:
        claims = jwt.decode(
            creds.credentials,
            settings.jwt_secret,
            algorithms=[settings.jwt_algorithm],
            audience=settings.jwt_audience,
            issuer=settings.jwt_issuer,
        )
    except jwt.PyJWTError:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="invalid or expired token",
            headers={"WWW-Authenticate": "Bearer"},
        )
    if claims.get("token_use") != "access":
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="not an access token",
        )
    return claims


def compute_signature(body: bytes) -> str:
    mac = hmac.new(settings.request_signing_secret.encode(), body, hashlib.sha256)
    return base64.b64encode(mac.digest()).decode()


def verify_signature(body: bytes, provided: str) -> bool:
    return hmac.compare_digest(compute_signature(body), provided or "")


def verify_p256_signature(public_key_pem: str, message: bytes, signature: bytes) -> bool:
    try:
        public_key = load_pem_public_key(public_key_pem.encode())
        public_key.verify(signature, message, ec.ECDSA(hashes.SHA256()))
        return True
    except (InvalidSignature, ValueError, TypeError):
        return False
