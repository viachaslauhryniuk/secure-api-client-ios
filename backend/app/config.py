import os
from datetime import timedelta


class Settings:

    jwt_secret: str = os.environ.get("SAC_JWT_SECRET", "dev-fallback")
    jwt_algorithm: str = "HS256"
    jwt_issuer: str = "secure-api-backend"     
    jwt_audience: str = "secure-api-client-ios"   

    access_token_ttl: timedelta = timedelta(minutes=15)
    refresh_token_ttl: timedelta = timedelta(days=30)

    default_scope: str = "profile:read accounts:read transactions:read"
    request_signing_secret: str = os.environ.get("SAC_SIGNING_SECRET", "dev-signing-secret")


settings = Settings()
