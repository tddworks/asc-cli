---
name: asc-auth
description: |
  Manage App Store Connect authentication using the `asc` CLI tool.
  Use this skill when:
  (1) Logging in with an API key: "asc auth login", "save my credentials", "set up authentication"
  (2) Managing multiple accounts: "asc auth list", "switch account", "use work account", "add another account"
  (3) Switching the active account: "asc auth use NAME", "switch to personal account"
  (4) Logging out: "asc auth logout", "remove credentials", "remove account"
  (5) Verifying current credentials: "asc auth check", "which account am I using?"
  (6) Updating account settings: "asc auth update --vendor-number", "save my vendor number"
  (7) Explaining the credentials file format (~/.asc/credentials.json)
  (8) Troubleshooting 401 auth errors or "missing credentials" errors
---

# asc auth — Multi-Account Authentication

Manages App Store Connect API key credentials in `~/.asc/credentials.json`. Supports multiple named accounts with an active account that all `asc` commands use automatically.

## Commands

### login — save an account

```bash
asc auth login \
  --key-id <KEY_ID> \
  --issuer-id <ISSUER_ID> \
  --private-key-path ~/.asc/AuthKey_KEYID.p8 \
  [--name <alias>]          # optional; defaults to "default"
  [--vendor-number <number>] # optional; for sales/finance reports
```

- `--name` must not contain spaces (use hyphens or underscores, e.g. `work-org`)
- If no `--name` is given, saves under `"default"`
- The saved account is automatically set as active
- Saving to an existing name **updates** it (safe overwrite)
- Use `--private-key` instead of `--private-key-path` to pass raw PEM content
- `--vendor-number` is optional; saved with credentials for auto-resolution by report commands

**Output** — `AuthStatus` JSON:

```json
{
  "data": [{
    "affordances": {
      "check": "asc auth check",
      "list":  "asc auth list",
      "login": "asc auth login --key-id <id> --issuer-id <id> --private-key-path <path>",
      "logout": "asc auth logout"
    },
    "issuerID": "abc-def-456",
    "keyID":    "KEYID123",
    "name":     "work",
    "source":   "file"
  }]
}
```

### list — show all saved accounts

```bash
asc auth list [--pretty] [--output table]
```

- Active account: `"isActive": true`
- Inactive accounts have a `"use"` affordance to switch

**Output** — array of `ConnectAccount`:

```json
{
  "data": [
    {
      "affordances": { "logout": "asc auth logout --name personal", "use": "asc auth use personal" },
      "isActive": false, "issuerID": "...", "keyID": "KEYID1", "name": "personal"
    },
    {
      "affordances": { "logout": "asc auth logout --name work" },
      "isActive": true,  "issuerID": "...", "keyID": "KEYID2", "name": "work"
    }
  ]
}
```

### use — switch active account

```bash
asc auth use <name>
# → Switched to account "work"
```

Throws `accountNotFound` if `<name>` doesn't exist. Run `asc auth list` first to see valid names.

### logout — remove an account

```bash
asc auth logout              # removes the active account
asc auth logout --name work  # removes a specific account
# → Logged out successfully
```

### update — modify an existing account

```bash
asc auth update [--name <alias>] --vendor-number <number>
```

- Updates the named account (or active account if `--name` is omitted)
- Currently supports `--vendor-number` — the vendor number used by `sales-reports` and `finance-reports` commands
- Loads existing credentials, merges the update, and saves back
- Throws `accountNotFound` if the account doesn't exist

**Output** — `AuthStatus` JSON (includes `vendorNumber`):

```json
{
  "data": [{
    "affordances": { "check": "asc auth check", "list": "asc auth list", ... },
    "issuerID": "abc-def-456",
    "keyID":    "KEYID123",
    "name":     "work",
    "source":   "file",
    "vendorNumber": "88012345"
  }]
}
```

### check — verify active credentials

```bash
asc auth check [--pretty] [--output table]
```

Shows active account name + source (`"file"` or `"environment"`). Shows `vendorNumber` if saved. No `name` field for environment credentials.

## Credential Resolution Order

All `asc` commands resolve credentials in this order:

1. **Active account in `~/.asc/credentials.json`** (set by `auth login` / `auth use`)
2. **Environment variables**: `ASC_KEY_ID`, `ASC_ISSUER_ID`, `ASC_PRIVATE_KEY_PATH` / `ASC_PRIVATE_KEY_B64` / `ASC_PRIVATE_KEY`

## Credentials File Format

```json
{
  "accounts": {
    "personal": { "issuerID": "...", "keyID": "KEYID1", "privateKeyPEM": "..." },
    "work":     { "issuerID": "...", "keyID": "KEYID2", "privateKeyPEM": "...", "vendorNumber": "88012345" }
  },
  "active": "work"
}
```

The `vendorNumber` field is optional — omitted from JSON when nil. It is used by `sales-reports` and `finance-reports` commands for auto-resolution when `--vendor-number` is not provided.

**Legacy migration**: Old single-credential files (`{ "keyID": ..., "issuerID": ..., "privateKeyPEM": ... }`) are automatically migrated to a `"default"` named account on first use.

## Typical Workflows

### First-time setup (single account)

```bash
asc auth login \
  --key-id KEYID123 \
  --issuer-id abc-def-456 \
  --private-key-path ~/.asc/AuthKey_KEYID123.p8

asc auth check --pretty    # verify source: "file"
asc apps list              # works without env vars
```

### Multiple accounts (personal + work)

```bash
# Add accounts
asc auth login --key-id K1 --issuer-id I1 --private-key-path ~/.asc/personal.p8 --name personal
asc auth login --key-id K2 --issuer-id I2 --private-key-path ~/.asc/work.p8 --name work

# List all
asc auth list --pretty

# Switch
asc auth use personal
asc apps list   # now uses personal account

asc auth use work
asc apps list   # now uses work account
```

### Save vendor number for reports

```bash
# During login
asc auth login --key-id K1 --issuer-id I1 --private-key-path key.p8 --vendor-number 88012345

# Or add to existing account
asc auth update --vendor-number 88012345

# Now reports auto-resolve vendor number
asc sales-reports download --report-type SALES --sub-type SUMMARY --frequency DAILY
```

### Remove an account

```bash
asc auth list              # find the name
asc auth logout --name personal
asc auth list              # confirm removal
```

## Error Reference

| Situation | Resolution |
|-----------|-----------|
| `accountNotFound("ghost")` | Run `asc auth list` to see valid names |
| Name contains spaces | Use hyphens/underscores: `--name my-org` |
| 401 Unauthorized on API calls | Run `asc auth check` to verify active credentials |
| No credentials anywhere | Run `asc auth login` or set `ASC_KEY_ID` env var |