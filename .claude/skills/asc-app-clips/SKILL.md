---
name: asc-app-clips
description: |
  Manage App Clips and App Clip default experiences using the `asc` CLI tool.
  Use this skill when:
  (1) Listing App Clips for an app: "asc app-clips list --app-id ID"
  (2) Listing default experiences for an App Clip: "asc app-clip-experiences list --app-clip-id ID"
  (3) Creating a default experience: "asc app-clip-experiences create --app-clip-id ID [--action OPEN|VIEW|PLAY]"
  (4) Deleting a default experience: "asc app-clip-experiences delete --experience-id ID"
  (5) Listing experience localizations: "asc app-clip-experience-localizations list --experience-id ID"
  (6) Creating an experience localization: "asc app-clip-experience-localizations create --experience-id ID --locale CODE [--subtitle TEXT]"
  (7) Deleting an experience localization: "asc app-clip-experience-localizations delete --localization-id ID"
  Trigger phrases: "app clip", "app clips", "clip experience", "clip localization", "default experience", "OPEN action", "VIEW action", "PLAY action", "App Clip card", "App Clip subtitle"
---

# App Clips with `asc`

Manage App Clips, their default experiences, and locale-specific card content through the App Store Connect API.

## Authentication

```bash
asc auth login --key-id <id> --issuer-id <id> --private-key-path ~/.asc/AuthKey.p8
```

## How to Navigate (CAEOAS Affordances)

Every JSON response contains an `"affordances"` field with ready-to-run commands — IDs already filled in. Start from the App Clip and navigate to experiences and localizations.

```json
{
  "id": "clip-abc",
  "appId": "6443417124",
  "bundleId": "com.example.MyApp.Clip",
  "affordances": {
    "listAppClips": "asc app-clips list --app-id 6443417124",
    "listExperiences": "asc app-clip-experiences list --app-clip-id clip-abc"
  }
}
```

## Typical Workflow

### Set up an App Clip experience with localizations

```bash
# 1. Find the App Clip for your app
asc app-clips list --app-id 6443417124 --pretty

# 2. Create a default experience (copy --app-clip-id from the listExperiences affordance)
asc app-clip-experiences create \
  --app-clip-id clip-abc \
  --action OPEN \
  --pretty

# 3. Add an English localization (copy --experience-id from the listLocalizations affordance)
asc app-clip-experience-localizations create \
  --experience-id exp-xyz \
  --locale en-US \
  --subtitle "Order faster with your loyalty card" \
  --pretty

# 4. Add a French localization
asc app-clip-experience-localizations create \
  --experience-id exp-xyz \
  --locale fr-FR \
  --subtitle "Commandez plus vite avec votre carte" \
  --pretty

# 5. Review all localizations
asc app-clip-experience-localizations list --experience-id exp-xyz --output table
```

### View all App Clip content at a glance

```bash
CLIP_ID=$(asc app-clips list --app-id APP_ID | jq -r '.data[0].id')
asc app-clip-experiences list --app-clip-id "$CLIP_ID" --output table

EXP_ID=$(asc app-clip-experiences list --app-clip-id "$CLIP_ID" | jq -r '.data[0].id')
asc app-clip-experience-localizations list --experience-id "$EXP_ID" --output table
```

## Commands

### `asc app-clips list`

List all App Clips for an app.

| Flag | Required | Description |
|------|----------|-------------|
| `--app-id` | yes | App Store Connect app ID |
| `--output table\|json` | no | Output format (default: json) |
| `--pretty` | no | Pretty-print JSON |

```bash
asc app-clips list --app-id 6443417124 --pretty
asc app-clips list --app-id 6443417124 --output table
```

### `asc app-clip-experiences list`

List default experiences for an App Clip.

| Flag | Required | Description |
|------|----------|-------------|
| `--app-clip-id` | yes | App Clip ID |
| `--output table\|json` | no | Output format |
| `--pretty` | no | Pretty-print JSON |

```bash
asc app-clip-experiences list --app-clip-id clip-abc --pretty
```

### `asc app-clip-experiences create`

Create a default experience for an App Clip.

| Flag | Required | Description |
|------|----------|-------------|
| `--app-clip-id` | yes | App Clip ID |
| `--action` | no | `OPEN`, `VIEW`, or `PLAY` |
| `--output table\|json` | no | Output format |
| `--pretty` | no | Pretty-print JSON |

```bash
asc app-clip-experiences create --app-clip-id clip-abc --action OPEN --pretty
asc app-clip-experiences create --app-clip-id clip-abc  # no action
```

### `asc app-clip-experiences delete`

Delete a default experience.

| Flag | Required | Description |
|------|----------|-------------|
| `--experience-id` | yes | Experience ID to delete |

```bash
asc app-clip-experiences delete --experience-id exp-xyz
```

### `asc app-clip-experience-localizations list`

List localizations for a default experience.

| Flag | Required | Description |
|------|----------|-------------|
| `--experience-id` | yes | Experience ID |
| `--output table\|json` | no | Output format |
| `--pretty` | no | Pretty-print JSON |

```bash
asc app-clip-experience-localizations list --experience-id exp-xyz --pretty
```

### `asc app-clip-experience-localizations create`

Create a localization for a default experience. Each locale gets its own subtitle shown in the App Clip card.

| Flag | Required | Description |
|------|----------|-------------|
| `--experience-id` | yes | Experience ID |
| `--locale` | yes | Locale code (e.g. `en-US`, `fr-FR`, `zh-Hans`) |
| `--subtitle` | no | Subtitle shown in the App Clip card |
| `--output table\|json` | no | Output format |
| `--pretty` | no | Pretty-print JSON |

```bash
asc app-clip-experience-localizations create \
  --experience-id exp-xyz \
  --locale en-US \
  --subtitle "Order faster with your loyalty card"
```

### `asc app-clip-experience-localizations delete`

Delete a localization.

| Flag | Required | Description |
|------|----------|-------------|
| `--localization-id` | yes | Localization ID to delete |

```bash
asc app-clip-experience-localizations delete --localization-id loc-abc
```

## Domain Models

**`AppClip`** — An App Clip linked to an app
- `id` — App Clip ID
- `appId` — parent App ID (injected from request, not returned by API)
- `bundleId` — App Clip bundle identifier (omitted from JSON if nil)
- Affordances: `listAppClips`, `listExperiences`

**`AppClipDefaultExperience`** — How an App Clip is invoked
- `id` — experience ID
- `appClipId` — parent App Clip ID (injected)
- `action` — `OPEN`, `VIEW`, or `PLAY` (omitted from JSON if nil)
- Affordances: `delete`, `listExperiences`, `listLocalizations`

**`AppClipDefaultExperienceLocalization`** — Locale-specific App Clip card content
- `id` — localization ID
- `experienceId` — parent experience ID (injected)
- `locale` — locale code (e.g. `en-US`)
- `subtitle` — subtitle shown in the App Clip card (omitted from JSON if nil)
- Affordances: `delete`, `listLocalizations`

## Full Command Reference

See [commands.md](../asc-cli/references/commands.md) for all flags and examples.
