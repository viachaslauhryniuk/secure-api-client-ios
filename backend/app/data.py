from .security import hash_password

DEMO_USERNAME = "demo"
DEMO_PASSWORD = "Password123!"


DUMMY_PASSWORD_HASH = hash_password("this-account-does-not-exist")

USERS: dict[str, dict] = {
    DEMO_USERNAME: {
        "user_id": "usr_8f14e45fceea167a",
        "username": DEMO_USERNAME,
        "password_hash": hash_password(DEMO_PASSWORD),
        "last_login_at": None,
        "profile": {
            "full_name": "Jane A. Doe",
            "email_masked": "j***@example.com",
            "phone_masked": "+1 (***) ***-4321",
            "kyc_status": "verified",
            "account_status": "active",
            "two_factor_enabled": True,
            "created_at": "2021-06-14T09:32:11Z",
            "accounts": [
                {
                    "id": "acc_chk_001",
                    "type": "checking",
                    "nickname": "Everyday Checking",
                    "iban_masked": "GB29 **** **** **** **34",
                    "currency": "USD",
                    "available_balance": 4820.55,
                    "ledger_balance": 4920.55,
                },
                {
                    "id": "acc_sav_002",
                    "type": "savings",
                    "nickname": "Rainy Day",
                    "iban_masked": "GB29 **** **** **** **88",
                    "currency": "USD",
                    "available_balance": 19320.00,
                    "ledger_balance": 19320.00,
                },
            ],
        },
    }
}


def get_user_by_username(username: str) -> dict | None:
    return USERS.get(username)


def get_user_by_id(user_id: str) -> dict | None:
    return next((u for u in USERS.values() if u["user_id"] == user_id), None)


REFRESH_TOKENS: dict[str, dict] = {}

ATTEST_CHALLENGES: set[str] = set()
ATTESTED_KEYS: dict[str, str] = {}
