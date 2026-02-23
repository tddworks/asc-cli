---
name: asc-cli
description: |
  Use the `asc` CLI tool (App Store Connect CLI) to manage iOS/macOS apps on App Store Connect.
  Use this skill when:
  (1) Submitting an app version for App Store review
  (2) Listing apps, versions, builds, localizations, or screenshots
  (3) Uploading screenshots or creating screenshot sets, or importing a screenshot ZIP
  (4) Managing TestFlight beta groups and testers
  (5) Managing app info localizations (name, subtitle, privacy policy URL)
  (6) Any task involving `asc` commands, App Store Connect operations, or navigating the CAEOAS affordance system
  (7) User says "submit AppName", "list my apps", "upload screenshots", "check builds", "update app name", etc.
---

# asc CLI — App Store Connect CLI

## Authentication

```bash
export ASC_KEY_ID="YOUR_KEY_ID"
export ASC_ISSUER_ID="YOUR_ISSUER_ID"
export ASC_PRIVATE_KEY_PATH="~/.asc/AuthKey_XXXXXX.p8"
```

Verify with: `swift run asc auth`

---

## CAEOAS — Follow the Affordances

Every response includes an `affordances` field with ready-to-run next commands. **Always use affordances** from prior responses instead of constructing commands from scratch.

```json
{
  "data": [{
    "id": "6748760927",
    "name": "My App",
    "affordances": {
      "listVersions": "asc versions list --app-id 6748760927"
    }
  }]
}
```

---

## Command Reference

See [commands.md](references/commands.md) for full command reference with options and examples.
See [api_reference.md](references/api_reference.md) for the underlying App Store Connect API endpoints and error codes.

### Quick reference

| Goal | Command |
|------|---------|
| List all apps | `asc apps list` |
| List versions | `asc versions list --app-id <id>` |
| Submit for review | `asc versions submit --version-id <id>` |
| List builds | `asc builds list --app-id <id>` |
| List localizations | `asc localizations list --version-id <id>` |
| List screenshot sets | `asc screenshot-sets list --localization-id <id>` |
| Upload screenshot | `asc screenshots upload --set-id <id> --file <path>` |
| Import screenshot ZIP | `asc screenshots import --version-id <id> --from export.zip` |
| TestFlight groups | `asc testflight groups list --app-id <id>` |
| List app infos | `asc app-infos list --app-id <id>` |
| List app info localizations | `asc app-info-localizations list --app-info-id <id>` |
| Update app name/subtitle | `asc app-info-localizations update --localization-id <id> --name <n>` |

---

## Common Workflows

### Submit an app for review

```
1. asc apps list                                    → find app ID
2. asc versions list --app-id <id>                  → find editable iOS version (PREPARE_FOR_SUBMISSION)
   → use affordances.submitForReview if present
3. asc versions submit --version-id <id>
```

**Prerequisite check**: `submitForReview` affordance only appears when `state` is editable. A 409 error means the version is missing required content (screenshots, build, description). Check App Store Connect UI.

### Upload screenshots

```
1. asc versions list --app-id <id>                  → get version ID
2. asc localizations list --version-id <id>         → get localization ID
3. asc screenshot-sets list --localization-id <id>  → get set ID for display type
4. asc screenshots upload --set-id <id> --file ./screenshot.png
```

### Import screenshots from ZIP (screenshot editor workflow)

```
1. Design screenshots in homepage/editor/index.html → Export ZIP
2. asc screenshots import --version-id <id> --from ./export.zip
```

### Update app name / subtitle

```
1. asc app-infos list --app-id <id>                          → get app info ID
2. asc app-info-localizations list --app-info-id <id>        → get localization ID
3. asc app-info-localizations update --localization-id <id> --name "New Name" --subtitle "New Subtitle"
```

### Check build availability

```
asc builds list --app-id <id> --limit 5
```

---

## Output Flags

```bash
asc apps list                    # compact JSON (default)
asc apps list --pretty           # pretty-printed JSON
asc apps list --output table     # table format
asc apps list --output markdown  # markdown table
```

---

## Error Handling

| Error | Meaning |
|-------|---------|
| 409 STATE_ERROR.ENTITY_STATE_INVALID | Version not ready (missing screenshots/build/metadata) |
| 401 | Auth credentials missing or invalid |
| 404 | Resource ID doesn't exist or wrong type passed |

When a submission fails with 409, inspect the version in App Store Connect web UI for missing requirements.