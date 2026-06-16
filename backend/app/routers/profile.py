from datetime import datetime, timezone

from fastapi import APIRouter, Depends, HTTPException, status

from ..data import get_user_by_id
from ..models import Account, ProfileResponse, SessionInfo
from ..security import get_current_claims

router = APIRouter(tags=["profile"])


@router.get("/profile", response_model=ProfileResponse)
def get_profile(claims: dict = Depends(get_current_claims)) -> ProfileResponse:
    user = get_user_by_id(claims["sub"])
    if user is None:
        raise HTTPException(status.HTTP_401_UNAUTHORIZED, "unknown subject")

    p = user["profile"]
    return ProfileResponse(
        user_id=user["user_id"],
        username=user["username"],
        full_name=p["full_name"],
        email_masked=p["email_masked"],
        phone_masked=p["phone_masked"],
        kyc_status=p["kyc_status"],
        account_status=p["account_status"],
        two_factor_enabled=p["two_factor_enabled"],
        created_at=p["created_at"],
        last_login_at=user.get("last_login_at") or p["created_at"],
        accounts=[Account(**a) for a in p["accounts"]],
        session=SessionInfo(
            issued_at=datetime.fromtimestamp(claims["iat"], tz=timezone.utc).isoformat(),
            expires_at=datetime.fromtimestamp(claims["exp"], tz=timezone.utc).isoformat(),
            scope=claims.get("scope", ""),
            device_bound=False,
        ),
    )
