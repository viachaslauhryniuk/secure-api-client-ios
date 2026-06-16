from fastapi import APIRouter, Depends, HTTPException, Request, status

from ..security import get_current_claims, verify_signature

router = APIRouter(tags=["secure"])


@router.post("/secure")
async def secure(request: Request, claims: dict = Depends(get_current_claims)) -> dict:
    body = await request.body()
    signature = request.headers.get("X-Signature", "")
    if not verify_signature(body, signature):
        raise HTTPException(status.HTTP_401_UNAUTHORIZED, "invalid request signature")
    return {"status": "accepted", "signed_bytes": len(body), "user_id": claims["sub"]}
