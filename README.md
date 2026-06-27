# secure-api-client-ios

A small iOS app I built to actually *understand* mobile security instead of just reading about it. It's a fake "secure API client" (login → profile → a protected action) wired up with the kind of defensive layers a real banking app uses, talking to a little Python backend I wrote alongside it.

It's a learning project — some parts are mocked on purpose, nothing here is production-ready. I built each layer one at a time until the concept clicked.

## What's in it

| Layer | What it does |
|---|---|
| **ATS + TLS** | HTTPS only; watched plain `http://` get blocked (and learned why `localhost` is the odd exception). |
| **Keychain** | Auth token lives in the Keychain (never UserDefaults), auto-login on launch, wiped on logout. |
| **Cert pinning** | Public-key (SPKI) pinning in a `URLSessionDelegate` — the app only trusts *my* server's key, so a MITM proxy gets dropped. |
| **Jailbreak detection** | A *signal*, not a wall: suspicious paths, `cydia://`, debugger check → an `isCompromisedDevice` flag + a warning banner. |
| **App Attest (mock) + Secure Enclave** | A real P256 key in the Secure Enclave signs server challenges; the backend verifies. ⚠️ Mocked trust chain, not Apple's `DCAppAttestService` — see caveats. |
| **Reverse-engineering check** | Ran `strings` on my own binary: URLs/pin are visible, but no real secrets leak (token's in the Keychain, not the binary). |
| **Final pipeline** | One guarded request path that chains them all: jailbreak check → token → attestation → pinned HTTPS. |

## How it's built

- **App:** SwiftUI, plain `URLSession` + `async/await`, CryptoKit. No third-party dependencies.
- **Backend:** Python / FastAPI — fake login (JWT), `/profile`, App Attest `challenge`/`register`/`assert` endpoints, self-signed TLS.

## Running it

**1. Make a local TLS cert** (gitignored, so generate your own):
```bash
cd backend && mkdir -p certs
openssl req -x509 -newkey rsa:2048 -nodes -keyout certs/key.pem -out certs/cert.pem -days 365 \
  -subj "/CN=localhost" -addext "subjectAltName=DNS:localhost,IP:127.0.0.1"
```

**2. Compute the pin** and paste it into `secureAPIClient/Network/PublicKeyPinner.swift` (`pinnedKeyHash`):
```bash
openssl x509 -in certs/cert.pem -pubkey -noout | openssl pkey -pubin -outform der \
  | openssl dgst -sha256 -binary | openssl enc -base64
```
*(If you generate a new cert, you must update the pin — otherwise pinning rejects it. That's the point of pinning.)*

**3. Run the backend:**
```bash
python3 -m venv .venv && .venv/bin/pip install -r requirements.txt
.venv/bin/uvicorn app.main:app --host 127.0.0.1 --port 8443 \
  --ssl-keyfile certs/key.pem --ssl-certfile certs/cert.pem
```

**4. Run the app:** open `secureAPIClient.xcodeproj` in Xcode and run. Log in with **`demo` / `Password123!`**.

## Honest caveats (it's a learning project)

- **App Attest is mocked.** It uses a *real* Secure Enclave key, but the backend just trusts the public key the client sends — there's no Apple certificate-chain attestation (that needs a physical device + a dev account). So it teaches the trust chain; a real app would use `DCAppAttestService`.
- **Self-signed cert, localhost only.** Everything runs against `127.0.0.1`. The cert and pin are mine.
- **Backend is in-memory.** Restart it and it forgets registered keys and sessions.
- **Don't ship any of this.** Demo creds, dev secrets, no rate limiting, etc.

## What I got out of it

Mostly one idea: **you can't trust the client.** `strings` reads your whole binary, pinning gets bypassed at runtime on a jailbroken phone, and jailbreak checks are just hints. Real security comes from the things that *don't* live in the app — keys in the Secure Enclave, secrets in the Keychain, and the **server verifying the client** instead of trusting it.
