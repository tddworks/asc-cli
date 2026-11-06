---
description: Save App Store Connect team or individual API keys as named accounts, switch between them, or use environment variables. Use when setting up credentials, managing several teams, or configuring CI.
---

# Auth

Saves App Store Connect API key credentials to `~/.asc/credentials.json`, with multiple named accounts and one active account used by every `asc` command. Environment variables work as a fallback.
Every flag: [command reference](../../commands.md#asc-auth).

## Quick start

```bash
asc auth login --key-id KEYID123 --issuer-id abc-def-456 --private-key-path ~/.asc/AuthKey_KEYID123.p8
asc auth check --pretty
asc apps list --pretty
```

## Workflows

### Work with several accounts

```bash
# Add personal and work accounts (--name defaults to "default"; no spaces)
asc auth login --key-id KEYID123 --issuer-id abc-def-456 \
  --private-key-path ~/.asc/AuthKey_personal.p8 --name personal
asc auth login --key-id WORKKEY456 --issuer-id xyz-ghi-789 \
  --private-key-path ~/.asc/AuthKey_work.p8 --name work

asc auth list --pretty          # all accounts, which one is active
asc auth use work               # switch the active account
asc auth check --pretty         # verify it

asc auth logout --name personal # remove a specific account
asc auth logout                 # remove the active account
```

`auth list` marks the active account; only inactive accounts get a `use` affordance:

```json
{
  "data": [
    {
      "affordances": {
        "logout": "asc auth logout --name personal",
        "use": "asc auth use personal"
      },
      "isActive": false,
      "issuerID": "abc-def-456",
      "keyID": "KEYID123",
      "name": "personal"
    },
    {
      "affordances": { "logout": "asc auth logout --name work" },
      "isActive": true,
      "issuerID": "xyz-ghi-789",
      "keyID": "WORKKEY456",
      "name": "work"
    }
  ]
}
```

`auth check` reports where credentials came from in `source`: `"file"` (includes `name`) or `"environment"` (no `name` field).

### Use an individual API key

An individual API key acts as the user it belongs to, with that user's role, and has no issuer ID. Leave out `--issuer-id`:

```bash
asc auth login --key-id KEYID123 --private-key-path ~/.asc/AuthKey_KEYID123.p8 --name me
```

`auth check` and `auth list` then have no `issuerID` field (`-` in tables). Requests are signed with `"sub": "user"` instead of an `iss` claim.

### Pass the key as PEM content instead of a file

```bash
asc auth login --key-id KEYID123 --issuer-id abc-def-456 \
  --private-key "$(cat ~/.asc/AuthKey_KEYID123.p8)" --name work
```

### Add a vendor number for reports

The vendor number (App Store Connect → Payments and Financial Reports) is used by `sales-reports` and `finance-reports`, which pick it up from the active account when `--vendor-number` is omitted.

```bash
asc auth login ... --vendor-number 12345678       # at login
asc auth update --vendor-number 12345678          # existing active account
asc auth update --name work --vendor-number 12345678
```

### CI: environment variables

```bash
export ASC_KEY_ID="YOUR_KEY_ID"
export ASC_ISSUER_ID="YOUR_ISSUER_ID"   # leave unset or empty for an individual key
export ASC_PRIVATE_KEY_PATH="~/.asc/AuthKey_XXXXXX.p8"
# or ASC_PRIVATE_KEY_B64 (base64 of the key), or ASC_PRIVATE_KEY (PEM content)
asc auth check   # source: "environment"
```

If more than one key variable is set, `ASC_PRIVATE_KEY_PATH` wins, then `ASC_PRIVATE_KEY_B64`, then `ASC_PRIVATE_KEY`.

## REST

The same operations are reachable via `asc web-server`, so a local web app (e.g. a setup wizard) can drive auth without spawning the CLI.

| Method | Path | CLI equivalent | Body |
|---|---|---|---|
| POST | `/api/v1/auth/accounts` | `asc auth login` | `{ "keyId", "issuerId"?, "privateKeyPEM", "name"?, "vendorNumber"? }` (no `issuerId` for an individual key) |
| GET | `/api/v1/auth/accounts` | `asc auth list` | — |
| GET | `/api/v1/auth/accounts/active` | `asc auth check` (saved accounts only; no env-var fallback, 404 when none is active) | — |
| PATCH | `/api/v1/auth/accounts/active` | `asc auth use NAME` | `{ "name": "personal" }` |
| PATCH | `/api/v1/auth/accounts/:name` | `asc auth update --vendor-number N` | `{ "vendorNumber": "12345678" }` |
| DELETE | `/api/v1/auth/accounts/active` | `asc auth logout` | — |
| DELETE | `/api/v1/auth/accounts/:name` | `asc auth logout --name X` | — |

```bash
curl -X POST http://localhost:8420/api/v1/auth/accounts \
  -H 'content-type: application/json' \
  -d '{
    "keyId": "KEYID123",
    "issuerId": "abc-def-456",
    "privateKeyPEM": "-----BEGIN PRIVATE KEY-----\nMIGTA...\n-----END PRIVATE KEY-----",
    "name": "personal"
  }'
```

The response has the same `{ "data": [ ... ] }` shape as `asc auth login`.

## Gotchas

- **Resolution order:** the active account in `~/.asc/credentials.json` first, then environment variables. A saved account shadows your env vars; run `asc auth check` to see which `source` is in use.
- **Security:** the REST auth routes write the API key PEM to `~/.asc/credentials.json`. `asc web-server` listens on all interfaces (`0.0.0.0`), so only run it on a trusted network or behind a firewall.
- `login` needs `--private-key-path` (supports `~`) or `--private-key`; if both are passed, the path wins.
- `login` makes the new account active. `logout` without `--name` removes the active account.
- `credentials.json` stores every account (key ID, issuer ID unless it's an individual key, PEM) under `accounts`, plus the name of the `active` one. An old single-credential file is migrated to an account named `default` on first use.

## See also

[reports](../reports/README.md) · [web-apps](../web-apps/README.md)
