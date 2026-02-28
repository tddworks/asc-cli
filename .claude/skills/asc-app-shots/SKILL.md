---
name: asc-app-shots
description: |
  AI-powered App Store screenshot planning skill. Analyzes screenshots using Claude's vision,
  fetches App Store metadata via `asc` commands, and writes a ScreenPlan JSON file ready for
  `asc app-shots generate`.
  Use this skill when:
  (1) User asks to "analyze my screenshots for App Store"
  (2) User asks to "create an app shots plan" or "generate screenshot plan"
  (3) User says "plan my App Store screenshots for app <id>"
  (4) User mentions "asc-app-shots" or asks for screenshot marketing copy planning
---

# asc-app-shots: Screenshot Plan Generator

This skill uses Claude's multimodal vision to analyze screenshot images, fetches App Store
metadata via `asc` CLI commands, and writes a `ScreenPlan` JSON file for use with
`asc app-shots generate`.

## Workflow

When invoked, follow these steps:

### Step 1 — Gather inputs

Ask the user for:
- **App ID** (`--app-id`) — e.g. `6736834466`
- **Version ID** (`--version-id`) — from `asc versions list --app-id <id>`
- **Locale** (default: `en-US`)
- **Screenshot files** — paths to the PNG/JPG files to plan for

If the user has already provided these, skip asking.

### Step 2 — Fetch App Store metadata

Run these `asc` commands and capture JSON output:

```bash
# Get app info ID
APP_INFO_ID=$(asc app-infos list --app-id <APP_ID> | jq -r '.data[0].id')

# Get app name and subtitle from app info localization
asc app-info-localizations list --app-info-id "$APP_INFO_ID" --locale <LOCALE>

# Get version localization (description, keywords, whatsNew)
VERSION_LOC_ID=$(asc version-localizations list --version-id <VERSION_ID> \
  | jq -r '.data[] | select(.locale == "<LOCALE>") | .id')
asc version-localizations list --version-id <VERSION_ID>
```

Extract from responses:
- `appName` from `AppInfoLocalization.name`
- `subtitle` from `AppInfoLocalization.subtitle`
- `description` from `AppStoreVersionLocalization.description`
- `keywords` from `AppStoreVersionLocalization.keywords`
- `whatsNew` from `AppStoreVersionLocalization.whatsNew`

### Step 3 — Analyze screenshots with vision

For each screenshot file provided, use your multimodal vision to:
1. Identify the primary UI elements shown
2. Determine what feature or benefit is being demonstrated
3. Note the visual style (colors, typography, layout)
4. Suggest a short heading (3-5 words) and subheading (6-10 words)
5. Write a `visualDirection` description of the screenshot content
6. Write an `imagePrompt` for enhancing the image

Choose a `tone` for the app based on the app category and metadata:
- `minimal` — clean, sparse, functional
- `playful` — fun, colorful, emoji-friendly
- `professional` — business, enterprise, serious
- `bold` — loud, impactful, high contrast
- `elegant` — premium, luxury, refined

Choose `layoutMode` for each screen:
- `center` — text centered over screenshot
- `left` — text left-aligned, screenshot right
- `tilted` — screenshot at an angle, text beside

### Step 4 — Generate ScreenPlan JSON

Combine metadata + vision analysis into the ScreenPlan schema (see `references/plan-schema.md`).

Use the app's dominant color palette for `colors`. If unsure, use sensible defaults:
- `primary`: dark navy or black
- `accent`: app's brand color
- `text`: white or light
- `subtext`: gray or semi-transparent white

### Step 5 — Write plan file

Write the ScreenPlan JSON to `app-shots-plan.json` in the current directory using the Write tool.

### Step 6 — Print next step

After writing the file, print:

```
✅ Plan written to app-shots-plan.json

Next step — enhance with Gemini:
  asc app-shots generate \
    --plan app-shots-plan.json \
    --gemini-api-key $GEMINI_API_KEY \
    --output-file enhanced-plan.json \
    --pretty \
    <screenshot files...>
```

## Example invocation

User: "Plan my App Store screenshots for app 6736834466, version v123abc. Here are the screenshots: screen1.png screen2.png screen3.png"

Claude:
1. Runs `asc app-infos list --app-id 6736834466` → gets appInfoId
2. Runs `asc app-info-localizations list --app-info-id <id>` → gets appName, subtitle
3. Runs `asc version-localizations list --version-id v123abc` → gets description, keywords
4. Reads screen1.png, screen2.png, screen3.png using vision
5. Generates ScreenPlan JSON with 3 screens
6. Writes to app-shots-plan.json
7. Prints next step instructions