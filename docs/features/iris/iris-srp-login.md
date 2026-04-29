# Iris SRP Login

**Status: implemented and validated against `idmsa.apple.com`.** Real login + trusted-device 2FA verified end-to-end: `asc iris auth login --apple-id <email> --interactive` returns an `IrisAuthSession` with populated `providerID`, `teamId`, `userEmail`, and `expiresAt`. All scaffolding ships: domain types, Apple SRP client (PBKDF2-derived `x`, RFC 5054-derived `S` and `M1`), idmsa HTTP layer, 2FA endpoints, olympus session lookup, file-backed session storage, CLI commands, and a composite cookie provider that wires SRP-stored sessions into existing iris commands automatically.

**Header set is load-bearing.** The first real-login attempts failed with a 401 on `POST /verify/trusteddevice/securitycode` despite a correct code. Root cause: `signin/init` and `signin/complete` were sending OAuth/Origin/Referer headers that no production reference (`XcodesOrg/XcodesApp`, `XcodesOrg/XcodesLoginKit`, `rorkai/App-Store-Connect-CLI`) sends. Apple's SRP session was being marked as an OAuth flow; the post-409 `GET /appleauth/auth` then returned 401, rotating `scnt` server-side, so the verify call arrived with a stale scnt and was rejected. Fix: narrow the SRP header set (see "Headers carried throughout" below) and use `?isRememberMeEnabled=false` + `rememberMe: false` on `signin/complete`. Set `ASC_IRIS_DEBUG=1` to dump every idmsa request/response (with `a`/`m1`/`m2` redacted) if you need to debug a future regression.

## Why this exists

The iris private API at `https://appstoreconnect.apple.com/iris/v1/` is the only path Apple exposes for several App Store Connect features (notably `submitWithNextAppStoreVersion` for IAP/subscription submissions). Iris is gated by **session cookies obtained from an Apple ID login** at `idmsa.apple.com`.

We already have **`BrowserIrisCookieProvider`** (`Sources/Infrastructure/Iris/BrowserIrisCookieProvider.swift`) which borrows cookies from the user's browser after they've signed in to App Store Connect manually. That works for desktop interactive use but **not for headless CI** — there's no browser to borrow from.

Three paths considered. Only one survives:

| Option | Verdict |
|---|---|
| Apple **API keys** (`.p8` files we already use for `asc auth`) | ❌ Authorize the public API only. Apple has no API-key path for iris. |
| **App-specific passwords** | ❌ Apple-designed for IMAP / CalDAV / CardDAV. `idmsa.apple.com` does not accept them as credentials for ASC web login. |
| **Full SRP login in the CLI** | ✅ The only Apple-blessed way to obtain iris cookies without a browser. This doc. |

## What "full SRP login" means

Apple's web login is a **Secure Remote Password (RFC 5054 / RFC 2945)** handshake against `idmsa.apple.com`, followed by a 2FA challenge, then an `olympus` session call to surface team metadata. Reproducing it locally yields the same `myacinfo` / `dqsid` / `itctx` cookies the browser would set, which `IrisClient` can then carry into iris calls.

Apple uses an SRP variant with these specifics:
- RFC 5054 group **2048** (2048-bit safe prime + generator)
- Two-step handshake: `init` (client sends `A`) → server replies with `salt` + `B` → `complete` (client sends `M1`)
- Password key derivation: **PBKDF2-HMAC-SHA256** with the iteration count and salt from the server's `init` response, derived password length **32 bytes**
- HKDF-SHA256 over the SRP shared key `K` to produce the request HMAC inputs
- `scnt` HTTP header threaded through every request after `init`
- 2FA gate: a `409 Conflict` from `complete` means trusted-device push or phone code is required; `200 OK` means no 2FA on this account
- Trust step: `POST /appleauth/auth/2sv/trust` after a successful 2FA code finalizes `myacinfo`

The Apple-specific quirks above are not in any official spec — they're observed behavior of `idmsa.apple.com` as of writing. Fastlane's `spaceship` library has been reverse-engineering this flow for years and is the most reliable cross-check for current Apple behavior:

- [`spaceship/lib/spaceship/two_step_or_factor_client.rb`](https://github.com/fastlane/fastlane/blob/master/spaceship/lib/spaceship/two_step_or_factor_client.rb) — 2FA challenge / verify / trust handling
- [`spaceship/lib/spaceship/client.rb`](https://github.com/fastlane/fastlane/blob/master/spaceship/lib/spaceship/client.rb) — header threading (`X-Apple-Widget-Key`, `scnt`, etc.) and the olympus session call

When Apple shifts the protocol, fastlane usually patches first; we should track their commits as a signal. Reproducing the flow ourselves still requires capturing a real successful login (see "Test strategy" below).

## CLI surface

Two subcommands under the existing `asc iris` tree.

### `asc iris auth login --apple-id <email> [--password <pwd>]`

Performs SRP `init` + `complete`. If the account succeeds without 2FA, persists the session and exits 0. If the account requires 2FA, prints the 2FA challenge (e.g. "Code sent to iPhone of …"), persists the *partial* session (so verify-code can resume), and exits non-zero with a message pointing at `asc iris auth verify-code`.

Flags:
- `--apple-id <email>` (required)
- `--password <pwd>` (optional; prompts if omitted, never echoed)
- `--method trusted-device | phone` (optional; default = trusted-device. Picks 2FA delivery channel when more than one is available.)
- `--trust` (optional, default true; sets `rememberMe` so subsequent logins skip 2FA on the same machine)

Examples:
```bash
asc iris auth login --apple-id dev@example.com
# Password: ************
# 2FA required. Code sent to your trusted devices.
# Run: asc iris auth verify-code <6-digit-code>

asc iris auth login --apple-id dev@example.com --method phone
# Password: ************
# 2FA required. Code sent to ***-***-1234.
```

### `asc iris auth verify-code <code> [--trust]`

Submits the 2FA code, hits the trust endpoint, then `olympus/v1/session`, then persists the full session.

```bash
asc iris auth verify-code 123456
# Logged in as dev@example.com (Team: My Studio LLC, providerID 12345)
# Session saved to ~/.asc/iris/session.json
```

### `asc iris auth logout`

Clears the persisted session. Doesn't revoke cookies on Apple's side (no public endpoint for that — the session simply expires).

### `asc iris status` (existing)

Already shows whether iris cookies are available; will be extended to surface the source (`browser`, `srp-login`, `environment`).

## Session resolution order

`CompositeIrisCookieProvider` (new) resolves in this order:
1. **Environment variable** `ASC_IRIS_COOKIES` (CI / explicit override)
2. **Persisted SRP login** (`~/.asc/iris/session.json` on Linux, Keychain on macOS)
3. **Browser cookies** (existing `BrowserIrisCookieProvider`)

The existing `BrowserIrisCookieProvider` is **not removed** — users on a desktop with an active ASC web session keep working without changes. SRP login lands as an alternative.

## Module map

```
Sources/
├── Domain/Auth/Iris/                                (new — pure value types & @Mockable protocols, zero I/O)
│   ├── IrisAuthCredentials.swift                    appleId, password
│   ├── IrisAuthSession.swift                        cookies, scnt, serviceKey, appleIDSessionID, providerID, teamId, userEmail, expiresAt
│   ├── IrisAuthRepository.swift                     @Mockable: login, requestTwoFactorCode, submitTwoFactorCode, logout
│   ├── IrisSessionRepository.swift                     @Mockable: save(IrisAuthSession), load() throws -> IrisAuthSession?, clear()
│   ├── IrisAuthError.swift                          invalidCredentials, twoFactorRequired, twoFactorRejected, applePromptRequired, networkError
│   ├── TwoFactorChallenge.swift                     method (trustedDevice/phone), maskedDestination, codeLength
│   └── PendingTwoFactorState.swift                  serialized partial session: scnt, serviceKey, appleIDSessionID, twoFactorCookieBag
│
├── Infrastructure/Iris/Auth/                        (new — implementations of Domain protocols)
│   ├── SRP/                                         (Apple-specific glue on top of swift-srp)
│   │   ├── AppleSRPClient.swift                     init() → A using swift-srp keys; completeWith(salt, B, iterations) computes Apple x via PBKDF2 then S using swift-srp's BigNum + config.k/g/N
│   │   └── AppleM1.swift                            HKDF-SHA256-derived M1 — Apple's variant, distinct from RFC 2945 proof
│   ├── IdmsaAPIClient.swift                         HTTP for idmsa.apple.com (signin/init, signin/complete, verify/<method>/securitycode, 2sv/trust); cookie jar & header threading
│   ├── OlympusClient.swift                          olympus/v1/session for team metadata
│   ├── IrisAuthSDKRepository.swift                  implements `Domain.IrisAuthRepository`; composes AppleSRPClient + IdmsaAPIClient + OlympusClient
│   ├── KeychainIrisSessionRepository.swift             implements `Domain.IrisSessionRepository` via macOS Keychain (Security framework)
│   ├── FileIrisSessionRepository.swift                 implements `Domain.IrisSessionRepository` via `~/.asc/iris/session.json`, written with `0600`
│   ├── CompositeIrisSessionRepository.swift            implements `Domain.IrisSessionRepository` by trying Keychain first, falling back to file (so macOS gets keychain protection, Linux silently falls through)
│   ├── KeychainIrisCookieProvider.swift             implements existing `Domain.IrisCookieProvider`; reads from any `IrisSessionRepository`
│   └── CompositeIrisCookieProvider.swift            implements `Domain.IrisCookieProvider`; resolution order env → stored → browser
│
└── ASCCommand/Commands/Iris/Auth/                   (new — CLI)
    ├── IrisAuthCommand.swift                        `asc iris auth`
    ├── IrisAuthLogin.swift                          `asc iris auth login`
    ├── IrisAuthVerifyCode.swift                     `asc iris auth verify-code`
    └── IrisAuthLogout.swift                         `asc iris auth logout`
```

`IrisCommand.subcommands` gets `IrisAuthCommand.self` appended. `ClientProvider` gets `makeIrisAuthRepository()` and `makeIrisCookieProvider()` updated to return `CompositeIrisCookieProvider`.

## Domain models

### `IrisAuthSession`

```swift
public struct IrisAuthSession: Sendable, Equatable, Codable {
    public let cookies: String              // joined "name=value; name=value"
    public let scnt: String                 // for any post-login follow-ups
    public let serviceKey: String           // widgetKey from Apple's session bootstrap
    public let appleIDSessionID: String     // X-Apple-ID-Session-Id
    public let providerID: Int64?           // from olympus
    public let teamId: String?              // from olympus
    public let userEmail: String
    public let expiresAt: Date              // best-guess from cookie max-age
}
```

Carries everything iris needs (cookies) plus everything a relogin needs (scnt, serviceKey, appleIDSessionID).

### `PendingTwoFactorState`

```swift
public struct PendingTwoFactorState: Sendable, Codable {
    public let scnt: String
    public let serviceKey: String
    public let appleIDSessionID: String
    public let twoFactorCookieBag: String   // cookies received between init and complete
    public let credentials: IrisAuthCredentials
    public let challenge: TwoFactorChallenge
}
```

Stored after `login` returns 2FA-required; consumed by `verify-code`.

### `IrisAuthError`

```swift
public enum IrisAuthError: LocalizedError {
    case invalidCredentials
    case twoFactorRequired(PendingTwoFactorState)
    case twoFactorCodeRejected(remainingAttempts: Int?)
    case applePromptRequired       // Apple wants the user to acknowledge a privacy prompt in a real browser
    case sessionExpired
    case networkFailure(underlying: Error)
}
```

## Apple flow reproduced

```
Step 0  GET  /appleauth/auth/signin                            → grab serviceKey + scnt headers + cookies
Step 1  POST /appleauth/auth/signin/init                       body: { a: A_pub_b64, accountName: email,
                                                                          protocols: ["s2k","s2k_fo"] }
                                                                → { iteration, salt, b: B_pub_b64, c: cookie, protocol }
Step 2  client computes:
          x = PBKDF2-SHA256(SHA256(password), salt, iterations, 32)
          v, M1 per RFC 5054 (with HKDF-derived M1 input — Apple-specific)
Step 3  POST /appleauth/auth/signin/complete?isRememberMeEnabled=false
                                                                body: { accountName, c, m1, m2, rememberMe: false }
                                                                → 200 OK   → step 6
                                                                → 409      → step 4 (2FA)
Step 4  GET  /appleauth/auth                                   → discover trusted-device & phone options
Step 5a POST /appleauth/auth/verify/trusteddevice/securitycode body: { code }
Step 5b POST /appleauth/auth/verify/phone/securitycode         body: { phoneNumber: { id }, securityCode: { code } }
Step 5c POST /appleauth/auth/2sv/trust                          → finalizes myacinfo
Step 6  GET  /olympus/v1/session                               → providerID, teamId, userEmail
```

Headers carried throughout (matches XcodesOrg/XcodesApp, XcodesOrg/XcodesLoginKit, and rorkai/App-Store-Connect-CLI byte-for-byte):
- `X-Apple-Widget-Key: <serviceKey>`
- `X-Requested-With: XMLHttpRequest`
- `Accept: application/json, text/javascript`
- `Content-Type: application/json` (on POST)
- `X-Apple-HC: <hashcash>` (signin/complete only)
- `scnt` and `X-Apple-ID-Session-Id` once Apple sets them

We do NOT send `X-Apple-OAuth-Client-Id`, `X-Apple-OAuth-Redirect-URI`, `X-Apple-OAuth-Response-Mode`, `X-Apple-OAuth-Response-Type`, `Origin`, or `Referer`. Adding any of these to the SRP requests taints the session: signin/complete still works, but the post-409 `GET /appleauth/auth` returns 401, rotates `scnt`, and `POST /verify/trusteddevice/securitycode` is rejected as out-of-sequence.

## Dependencies to add to `Package.swift`

| Dependency | Purpose | License |
|---|---|---|
| `https://github.com/adam-fowler/swift-srp` | RFC 5054 group constants (`SRPConfiguration<SHA256>(.N2048)`), BigNum, key-pair generation, proof helpers | Apache 2.0 |

That's the only direct addition. Transitively it brings:
- [`apple/swift-crypto`](https://github.com/apple/swift-crypto) (Apache 2.0) — `SHA256`, `HMAC`, PBKDF2 (`Insecure.PBKDF2`), HKDF, constant-time comparison
- [`adam-fowler/big-num`](https://github.com/adam-fowler/big-num) (Apache 2.0) — BigInt arithmetic, including modular exponentiation on the 2048-bit prime

We pick `swift-srp` over rolling our own SRP because:
- It already has the RFC 5054 group 2048 safe prime + generator constants verified against published test vectors.
- It owns the BigNum interop so we don't maintain that surface.
- The maintainer is the same Adam Fowler we're already pulling in via Hummingbird — known quantity.
- Active: last release within the past month at the time of writing.

### Caveat: `swift-srp` does not let us override how `x` is derived

`SRPClient.calculateSharedSecret(username:password:salt:...)` hardcodes the RFC 5054 derivation `x = H(salt | H(username | ":" | password))`. Apple uses **PBKDF2-HMAC-SHA256** with a server-supplied iteration count instead. We therefore can't call that public API directly.

Workaround (small, isolated): we derive `x` ourselves using PBKDF2 and compute the shared secret `S` with the same math `swift-srp` uses internally, but feeding our Apple-derived `x`. About 20 lines, lives in our `AppleSRPClient`. Everything else (`BigNum`, `configuration.k/g/N`, key generation, padding rules, hash helpers) comes straight from `swift-srp`.

We could upstream a PR adding a public hook for custom `x` derivation, but that's outside the scope of this build — the workaround is contained.

## Test strategy

Strict TDD. Each slice has a red test before any production code.

### Crypto primitives (slice 1)
- **RFC 5054 base correctness comes free** — `swift-srp` already has its own test suite verified against RFC 5054 vectors, Mozilla's verifier vectors, and several cross-implementations. We do not re-test what they own.
- **Apple-specific test vectors**: we test only our delta — Apple's PBKDF2-based `x` derivation and HKDF-based `M1`. Captured from a single real successful login through `mitmproxy`. Stored as `Tests/InfrastructureTests/Iris/Auth/Fixtures/apple-srp-vectors.json` (no real password — only the post-derivation values: salt, iterations, expected `x`, expected `M1`).

### Idmsa flow (slices 2–3)
- `IdmsaAPIClient` accepts an injected `URLSession` (via `URLProtocol` mock or `XCTNetworking` shim).
- Tests stub each endpoint and assert the request body shape, headers (`scnt`, `X-Apple-Widget-Key`), and that the client correctly threads `scnt` through follow-up calls.
- Tests cover both 200-OK (no 2FA) and 409 (2FA required) branches.
- 2FA tests cover trusted-device push and phone-code paths separately.

### Olympus + session (slice 4)
- Stub `olympus/v1/session` JSON, assert `IrisAuthSession.providerID` / `.teamId` / `.userEmail` map correctly.

### Persistence (slice 5)
- Round-trip: write → load → assert equality.
- Permission test: written file is `0600` on Unix.
- Keychain tests: macOS-only, conditionally skipped on CI without keychain.

### CLI commands (slice 6)
- Mock `IrisAuthRepository`, exact JSON snapshot per `formatAgentItems`.
- Two-step flow: `login` returns `twoFactorRequired` → output mentions "verify-code" → `verify-code` succeeds → output shows team info.

## Milestones

| # | Slice | Done when |
|---|---|---|
| 1 | Add `swift-srp` to `Package.swift`; wire `AppleSRPClient` (Apple-x via PBKDF2, S via swift-srp's BigNum + config) and `AppleM1` (HKDF-derived) | Apple-captured test vectors pass; ~150 LoC + tests |
| 2 | Idmsa happy path (no 2FA) | `IrisAuthRepository.login` returns full `IrisAuthSession` against stubbed Apple endpoints |
| 3 | 2FA flow (trusted-device + phone) | `verifyTwoFactorCode` succeeds; `IrisAuthError.twoFactorRequired` carries the right `PendingTwoFactorState` |
| 4 | Olympus + composite cookie provider | iris calls succeed end-to-end against a stubbed test server |
| 5 | Keychain / file persistence | Login → restart process → cookies still resolve from storage |
| 6 | CLI commands `login` / `verify-code` / `logout` | Snapshot tests green; `asc iris status` reflects source `srp-login` |
| 7 | Doc + CHANGELOG | This doc updated with implementation status; CHANGELOG `[Unreleased] → Added` |
| 8 | Real-login validation | `asc iris auth login --interactive` returns a populated `IrisAuthSession` against the live `idmsa.apple.com`, hsa2 trusted-device path; required narrowing the SRP header set and flipping `rememberMe` to `false` |

## Risks (called out so we don't kid ourselves)

1. **Apple changes the SRP variant** — `idmsa.apple.com` is an unofficial surface; response shapes have shifted historically. We'll likely need explicit retry / fallback paths over time. Mitigation: keep the SRP layer narrow and behind a single repo so adjustments are localized.
2. **Capturing reliable test vectors needs a real login** — slice 1's tests are weak without it. The user (or a maintainer with a sacrificial Apple ID) must run a captured login through mitmproxy at least once.
3. **Apple privacy prompt** — sometimes Apple gates login behind a prompt only resolvable in a real browser ("acknowledge new privacy terms"). We surface `IrisAuthError.applePromptRequired` and tell the user to open Safari; can't bypass programmatically.
4. **Keychain on Linux** — keychain is macOS-only. Linux falls back to a 0600 file; users on Linux give up macOS keychain's hardware-backed protection.
5. **Two-step CLI is mandatory** — single-command interactive (read 2FA code from stdin) makes scripting awkward. Two-step requires a state file but keeps each command idempotent and testable.

## Out of scope (deliberately)

- **Auto-detecting whether browser cookies are still valid before falling back to SRP login.** The composite resolves on a static priority order; we don't probe.
- **Refresh-without-relogin.** Apple's session typically lasts ~30 days; on expiry the user reruns `login` + `verify-code`. No refresh token endpoint exists on iris.
- **Any non-`appstoreconnect.apple.com` Apple property.** This is iris-specific. App Store Connect's public API still uses `.p8` API keys via the existing `asc auth` flow.

## See also

- `docs/features/iap-subscriptions/submission-iris-parity.md` — the original gap that motivated this build
- `Sources/Infrastructure/Iris/IrisClient.swift` — the iris HTTP layer that consumes the cookies SRP login produces
- `Sources/Infrastructure/Iris/BrowserIrisCookieProvider.swift` — the existing browser-based path; remains as the third resolver in the composite
