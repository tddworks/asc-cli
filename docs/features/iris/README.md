---
description: Call App Store Connect's private iris API with an Apple ID session instead of an API key. Use when you need web-UI-only features such as creating an app, queuing an IAP with the next version, or reading rejection messages.
---

# Iris (Private API)

Iris is the private API behind the App Store Connect web UI. It exposes things the public API doesn't, such as app creation. It uses Apple ID session cookies, not JWT API keys. Every flag: [command reference](../../commands.md#asc-iris).

Iris is purely additive: your API-key setup (`asc auth`) and every script built on it keep working unchanged. You only need an iris session for `asc iris …` commands.

## Quick start

```bash
asc iris auth login --apple-id dev@example.com --interactive   # password + 2FA prompt
asc iris status --pretty
asc iris apps create --name "My App" --bundle-id com.example.app --sku MYSKU --pretty
```

## Sign in

Three ways to get a session, resolved in this order:

1. **Apple ID login** (`asc iris auth login`) — a saved, unexpired session.
2. **`ASC_IRIS_COOKIES` environment variable** — raw cookie string, for CI. It does not override a live saved session.
3. **Browser cookies** — auto-extracted from Chrome, Safari or Firefox after you log in to [appstoreconnect.apple.com](https://appstoreconnect.apple.com).

### Apple ID login (SRP + 2FA)

```bash
# One process: prompts for the password and then the 2FA code on stdin
asc iris auth login --apple-id dev@example.com --interactive

# Or two steps: login writes pending state, verify-code finishes it
asc iris auth login --apple-id dev@example.com
asc iris auth verify-code 123456
# → JSON summary (userEmail, teamId, expiresAt); session saved to ~/.asc/iris/session.json

asc iris status          # shows where the session came from and how many cookies
asc iris auth logout     # clears the saved session
```

Omit `--password` to be prompted (never echoed). The session lasts about 30 days; when it expires, sign in again. There is no refresh endpoint.

### Browser cookies

Log in to App Store Connect in your browser; `asc` reads the cookies itself. The essential cookie is `myacinfo` (on `.apple.com`); `itctx`, `dqsid`, `wosid` etc. are collected from `appstoreconnect.apple.com`.

### CI

```bash
export ASC_IRIS_COOKIES="myacinfo=DAWT...; itctx=eyJ..."
asc iris apps create --name "My App" --bundle-id com.example.app --sku MYSKU
```

## Workflows

### Create a new app

```bash
# 1. Check you have a session
asc iris status --pretty

# 2. Create the app
asc iris apps create \
    --name "My New App" \
    --bundle-id com.example.newapp \
    --sku com.example.newapp \
    --pretty

# Multi-platform, or a different primary locale
asc iris apps create --name "My App" --bundle-id com.example.app --sku MYSKU --platforms IOS --platforms MAC_OS --version 2.0
asc iris apps create --name "我的应用" --bundle-id com.example.app --sku MYSKU --primary-locale zh-Hans

# 3. Continue with public API commands
asc versions list --app-id <id-from-step-2>
asc app-infos list --app-id <id-from-step-2>
```

`asc iris status` output (each item inside `{"data": [...]}`):

```json
{
  "affordances" : {
    "createApp" : "asc iris apps create --name <name> --bundle-id <id> --sku <sku>",
    "listApps" : "asc iris apps list",
    "submitIAP" : "asc iris iap-submissions create --iap-id <iap-id>"
  },
  "cookieCount" : 5,
  "source" : "browser"
}
```

Apps from `asc iris apps list` / `create` carry `listVersions` and `listAppInfos` affordances pointing at the public-API commands.

### Other iris commands

- `asc iris iap-submissions create|delete` — queue an IAP with the next app version, or dequeue it. See [Submit with products](../submit-with-products/README.md).
- `asc iris resolution-center get` — read App Review's rejection messages. See [Resolution Center](../resolution-center/README.md).
- `asc iris app-compliance list|declare` — answer the App Compliance page (China mainland Security Assessment, AIGC). See [App Compliance](../app-compliance/README.md).

## REST

| Method | Path | CLI equivalent |
|---|---|---|
| POST | `/api/v1/iris/iap/:iapId/submissions` | `asc iris iap-submissions create` |
| DELETE | `/api/v1/iris/iap-submissions/:submissionId` | `asc iris iap-submissions delete` |
| GET | `/api/v1/iris/review-submissions/:submissionId/resolution-center` | `asc iris resolution-center get` |
| GET | `/api/v1/iris/apps/:appId/compliance-requirements` | `asc iris app-compliance list` |
| POST | `/api/v1/iris/apps/:appId/compliance-requirements/:requirementId/declare` | `asc iris app-compliance declare` |

## Gotchas

- Apple API keys (`.p8`) never authorize iris, and app-specific passwords are not accepted for App Store Connect web login. An Apple ID session is the only way in.
- `asc iris auth logout` only deletes the local session; Apple has no endpoint to revoke it, so the cookies simply expire.
- Without a session, iris commands fail. Run `asc iris status` first in scripts.
- Set `ASC_IRIS_DEBUG=1` to dump every Apple login request/response (secrets redacted) when debugging a login failure.

## See also

- [Iris SRP login design](iris-srp-login.md) — how the Apple ID login works, session storage, and why ([flow diagram](iris-srp-flow.html))
- [Authentication (API keys)](../asc-auth/README.md)
- [Submit with products](../submit-with-products/README.md)
- [Resolution Center](../resolution-center/README.md)
