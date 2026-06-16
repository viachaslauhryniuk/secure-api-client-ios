from fastapi import FastAPI

from .routers import attest, auth, profile, secure

app = FastAPI(title="Secure API Client Backend", version="0.4.0")

app.include_router(auth.router)
app.include_router(profile.router)
app.include_router(secure.router)
app.include_router(attest.router)


@app.get("/health", tags=["meta"])
def health() -> dict:
    return {"status": "ok", "service": "secure-api-backend", "version": app.version}
