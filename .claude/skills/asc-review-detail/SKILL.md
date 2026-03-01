---
name: asc-review-detail
description: |
  Manage App Store review contact info and demo account settings using the `asc` CLI tool.
  Use this skill when:
  (1) Getting current review info: "asc version-review-detail get --version-id ID"
  (2) Setting review contact info before submission: "asc version-review-detail update --version-id ID ..."
  (3) Configuring demo account credentials for App Review team
  (4) User asks "set review info", "add review contact", "configure demo account", "fix reviewContactCheck"
  (5) Diagnosing a failed reviewContactCheck from asc versions check-readiness
---

# asc version-review-detail

Manage App Store review information (contact details + demo account) for a version. Required before submission — the App Review team needs contact info to reach you if there's an issue.

## Commands

### get — fetch current review info

```bash
asc version-review-detail get --version-id <VERSION_ID> [--pretty]
```

Returns an empty record (`id: ""`) when review info has never been set.

### update — set or update review info (upsert)

```bash
asc version-review-detail update --version-id <VERSION_ID> \
  [--contact-first-name <name>] \
  [--contact-last-name <name>] \
  [--contact-phone <phone>] \
  [--contact-email <email>] \
  [--demo-account-required <true|false>] \
  [--demo-account-name <username>] \
  [--demo-account-password <password>] \
  [--notes <text>]
```

**Upsert:** Creates a new record if none exists (POST), patches the existing one if it does (PATCH). Only supplied flags are sent — unspecified fields are left unchanged on an existing record.

## Typical Pre-Submission Workflow

```bash
# 1. Check what's currently set
asc version-review-detail get --version-id <VERSION_ID> --pretty

# 2. Set contact info (minimum to clear reviewContactCheck warning)
asc version-review-detail update --version-id <VERSION_ID> \
  --contact-first-name Jane \
  --contact-email dev@example.com \
  --contact-phone "+1-555-0100"

# 3. If app requires a demo account
asc version-review-detail update --version-id <VERSION_ID> \
  --demo-account-required true \
  --demo-account-name demo_user \
  --demo-account-password "secret" \
  --notes "Tap 'Sign In' then use the credentials above"

# 4. Verify check-readiness passes reviewContactCheck
asc versions check-readiness --version-id <VERSION_ID> --pretty

# 5. Submit
asc versions submit --version-id <VERSION_ID>
```

## JSON Output Shape

```json
{
  "data": [
    {
      "affordances": {
        "getReviewDetail":    "asc version-review-detail get --version-id <id>",
        "updateReviewDetail": "asc version-review-detail update --version-id <id>"
      },
      "contactEmail": "dev@example.com",
      "contactFirstName": "Jane",
      "contactLastName": "Smith",
      "contactPhone": "+1-555-0100",
      "demoAccountRequired": false,
      "id": "rd-abc123",
      "versionId": "<VERSION_ID>"
    }
  ]
}
```

Nil optional fields (`contactFirstName`, `contactEmail`, `demoAccountName`, `notes`, etc.) are omitted from JSON output.

## Reading reviewContactCheck in check-readiness

```json
"reviewContactCheck": { "pass": false, "message": "Review contact info is missing" }
```

This is a **SHOULD FIX** warning — it does NOT block `isReadyToSubmit`. Fix it with:

```bash
# Copy updateReviewDetail affordance from version-review-detail get output
asc version-review-detail update --version-id <id> --contact-email dev@example.com --contact-phone "+1-555-0100"
```

## Key Computed Properties

| Property | Logic |
|----------|-------|
| `hasContact` | `contactEmail != nil && contactPhone != nil` |
| `demoAccountConfigured` | `!demoAccountRequired \|\| (name != nil && password != nil)` |

`hasContact` feeds `reviewContactCheck.pass` in `asc versions check-readiness`.

## CAEOAS Affordances

`AppStoreVersion` includes `getReviewDetail` — follow it from any version listing:

```bash
VERSION=$(asc versions list --app-id "$APP_ID" | jq -r '.data[0]')
eval "$(echo "$VERSION" | jq -r '.affordances.getReviewDetail') --pretty"
```
