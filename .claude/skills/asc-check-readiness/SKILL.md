---
name: asc-check-readiness
description: |
  Run pre-flight submission checks for an App Store version using the `asc` CLI tool.
  Use this skill when:
  (1) Checking if a version is ready to submit to App Store review
  (2) Diagnosing why a version cannot be submitted (missing build, no pricing, wrong state)
  (3) Running a CI/CD gate before calling `asc versions submit`
  (4) User asks "is my version ready?", "check readiness", "why can't I submit?",
      "run pre-flight checks", "check submission requirements", or any submission-readiness task
  (5) Building an automated pipeline that conditionally submits based on readiness
---

# asc versions check-readiness

Pre-flight check that aggregates all App Store submission requirements for a version.

## Command

```bash
asc versions check-readiness --version-id <VERSION_ID> [--pretty]
```

Runs 6 API checks and returns a `VersionReadiness` report.

## Reading the Output

### Top-level decision field

```
"isReadyToSubmit": true  → safe to submit; affordances.submit is present
"isReadyToSubmit": false → one or more MUST FIX checks failed
```

### Check severity

| Field | Severity | Blocks `isReadyToSubmit`? |
|-------|----------|--------------------------|
| `stateCheck` | MUST FIX | Yes — state must be `PREPARE_FOR_SUBMISSION` |
| `buildCheck` | MUST FIX | Yes — build must be linked, valid, not expired |
| `pricingCheck` | MUST FIX | Yes — app must have a price schedule configured |
| `reviewContactCheck` | SHOULD FIX | No — warning only, submission still proceeds |
| `localizations[].pass` | SHOULD FIX | No — Apple may reject post-submit |

### Build check fields

```json
"buildCheck": {
  "linked": true,
  "valid": true,
  "notExpired": true,
  "buildVersion": "2.1.0 (102)",
  "pass": true
}
```

`pass` = `linked && valid && notExpired`

## CAEOAS — Use Affordances

When `isReadyToSubmit == true`, the response includes `affordances.submit`:

```json
"affordances": {
  "checkReadiness": "asc versions check-readiness --version-id v-123",
  "listLocalizations": "asc version-localizations list --version-id v-123",
  "submit": "asc versions submit --version-id v-123"
}
```

**Always copy `affordances.submit` directly** — never construct the submit command manually.
When `isReadyToSubmit == false`, `affordances.submit` is absent.

## Typical Workflow

```bash
# 1. Find the version in PREPARE_FOR_SUBMISSION
asc versions list --app-id <APP_ID> --output table

# 2. Check readiness (use checkReadiness affordance from step 1 output)
asc versions check-readiness --version-id <VERSION_ID> --pretty

# 3a. Ready → submit using affordances.submit value
asc versions submit --version-id <VERSION_ID>

# 3b. Not ready → diagnose and fix (see Fix Guide below)
```

## Fix Guide

| Failing check | How to fix |
|---------------|-----------|
| `stateCheck` fails | Version is already live or in review — create a new version with `asc versions create` |
| `buildCheck.linked == false` | Link a build: `asc versions set-build --version-id <id> --build-id <id>` |
| `buildCheck.valid == false` | Build is still processing — wait and re-check, or upload a new build |
| `buildCheck.notExpired == false` | Build expired — upload a new build with `asc builds upload` |
| `pricingCheck` fails | Set up pricing in App Store Connect web UI (no `asc` command for pricing) |
| `reviewContactCheck` fails | `asc version-review-detail update --version-id <id> --contact-email dev@example.com --contact-phone "+1-555-0100"` |

## CI Gate Script

```bash
#!/bin/bash
set -e
RESULT=$(asc versions check-readiness --version-id "$VERSION_ID")
IS_READY=$(echo "$RESULT" | jq -r '.data[0].isReadyToSubmit')

if [ "$IS_READY" = "true" ]; then
  eval "$(echo "$RESULT" | jq -r '.data[0].affordances.submit')"
else
  echo "NOT ready. Failing checks:"
  echo "$RESULT" | jq '.data[0] | {stateCheck, buildCheck, pricingCheck}'
  exit 1
fi
```
