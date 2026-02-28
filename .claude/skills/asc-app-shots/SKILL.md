---
name: asc-app-shots
description: |
  AI-powered App Store screenshot planning skill. Fetches app metadata from App Store Connect
  via `asc` CLI, analyzes screenshots using Claude's vision to extract colors and layout,
  summarizes the app description, and writes a ScreenPlan JSON file ready for
  `asc app-shots generate` to produce final marketing screenshots via Gemini.
  Use this skill when:
  (1) User asks to "analyze my screenshots for App Store"
  (2) User asks to "create an app shots plan" or "generate screenshot plan"
  (3) User says "plan my App Store screenshots for app ID"
  (4) User mentions "asc-app-shots" or asks for screenshot marketing copy planning
---

# asc-app-shots: Screenshot Plan Generator

Two-step workflow:
1. **This skill** — fetch metadata + analyze screenshots → write `app-shots-plan.json`
2. **`asc app-shots generate`** — read plan + call Gemini image generation → output PNG files

---

## Step 1 — Gather inputs

Ask the user for (skip if already provided):
- **App ID** — e.g. `6736834466`
- **Version ID** — from `asc versions list --app-id <id>`
- **Locale** — default: `en-US`
- **Screenshot files** — paths to PNG/JPG files to plan

---

## Step 2 — Fetch App Store metadata

Run these commands and extract the fields:

```bash
# 1. App name + tagline (subtitle)
APP_INFO_ID=$(asc app-infos list --app-id <APP_ID> | jq -r '.data[0].id')
asc app-info-localizations list --app-info-id "$APP_INFO_ID"
# → appName from .name, tagline from .subtitle (fallback: empty string)

# 2. Full description + keywords
asc version-localizations list --version-id <VERSION_ID>
# → description from .description (for locale), keywords from .keywords
```

**Summarize `appDescription`** from the full `.description`:
- Write 2-3 focused sentences capturing the app's **purpose** and **target audience**
- Keep it under 200 characters — this context is prepended to every Gemini imagePrompt
- Example: "AppNexus manages iOS/macOS apps on App Store Connect. A unified dashboard for versions, metadata, screenshots, and AI-powered store optimization. Built for indie developers who want full control without opening a browser."
- If description is unavailable, leave `appDescription` out of the plan

---

## Step 3 — Analyze screenshots with vision

Read each screenshot file. For each one, determine:

### Colors (from the first/hero screenshot)
Extract the app's dominant color palette to populate `colors`:
- `primary` — dominant background color (usually dark: navy, black, deep gray)
- `accent` — brand/highlight color (button tints, active states, logo color)
- `text` — heading text color (usually white or near-white)
- `subtext` — secondary text color (gray, muted)

**Fallbacks if colors are ambiguous:** `#0D1B2A` / `#4A7CFF` / `#FFFFFF` / `#A8B8D0`

### Hero vs Standard — App Store design convention (CRITICAL)

**Only `index: 0` is the hero screenshot.** All others (`index: 1, 2, 3...`) are standard screenshots.

| | Hero (index 0) | Standard (index 1+) |
|---|---|---|
| Device angle | Tilted ~8-10° | Upright, straight (0-2°) |
| Device size | ~70% canvas | ~80% canvas, fills frame |
| Effects | Radial glow, floating dots, light streaks | Subtle gradient or flat background only |
| Text placement | Heading above, subheading below | Heading above device, subheading below |
| Purpose | Grab attention in search results | Show features clearly |
| layoutMode | `center` or `tilted` | `center` |

### Per-screen config
For each screenshot:
1. **heading** — 2-5 word benefit headline (what does the user gain?)
2. **subheading** — 6-12 word supporting text (how? for whom?)
3. **layoutMode** — always `center` for standard; `center` or `tilted` for hero
4. **visualDirection** — 1-2 sentence factual description of what the UI shows
5. **imagePrompt** — Gemini generation prompt (see formula below)

### imagePrompt Formula (CRITICAL — sent directly to Gemini for image generation)

Always quote **exact heading and subheading text** — Gemini renders them in the image.

**Hero (index 0) — cinematic, tilted, atmospheric:**
```
"Generate a premium App Store hero screenshot. The uploaded iPhone UI is displayed in a
sleek tilted device mockup (~8 degrees) centered on a [dark] canvas ([hex]). Bold white
heading '[EXACT heading]' above the device, with [color] subtext '[EXACT subheading]' below.
[Accent color] radial glow behind the device. [Floating dots / light streaks]. Premium quality."
```

> Example: "Generate a premium App Store hero screenshot. The uploaded iPhone UI is displayed in a sleek tilted device mockup (~10 degrees) centered on a deep navy canvas (#0A0F1E). Bold white heading 'All Your Apps' above the device, with soft blue-gray subtext 'Manage your entire App Store portfolio in one place' below. Brilliant electric blue radial glow (#4A90E2) pulses behind the device. Floating micro-dots add cinematic depth. Professional, editorial, premium quality."

**Standard (index 1+) — clean, upright, UI-focused:**
```
"Generate a clean App Store feature screenshot. The uploaded iPhone UI is displayed upright
and centered, filling most of the canvas on a [dark] background ([hex]). Bold white heading
'[EXACT heading]' above the device, with [color] subtext '[EXACT subheading]' below.
Subtle background vignette. Clean, minimal, editorial quality."
```

> Example: "Generate a clean App Store feature screenshot. The uploaded iPhone UI is displayed upright and centered, filling most of the canvas on a deep navy background (#0A0F1E). Bold white heading 'Ship With Confidence' above the device, with muted blue-gray subtext 'App Info, Screenshots, and AI tools in one tap' below. Subtle background vignette. Clean, minimal, editorial quality."

### Tone (for the whole plan)
Choose based on app category + metadata:
- `minimal` — tools, utilities, productivity
- `playful` — games, kids, lifestyle
- `professional` — business, finance, enterprise
- `bold` — sports, media, entertainment
- `elegant` — fashion, luxury, wellness

---

## Step 4 — Write plan file

Combine metadata + vision analysis into `app-shots-plan.json` (see `references/plan-schema.md` for schema).

Use the Write tool to save the file in the current directory (or alongside the screenshots if in a subdirectory).

---

## Step 5 — Print next step

```
✅ Plan written to app-shots-plan.json

Next step — generate marketing screenshots with Gemini:
  asc app-shots generate \
    --plan app-shots-plan.json \
    --gemini-api-key $GEMINI_API_KEY \
    --output-dir app-shots-output \
    <screenshot files...>

Generated PNGs → app-shots-output/screen-0.png, screen-1.png, ...
```

---

## Example invocation

User: "Plan App Store screenshots for app 6736834466, version v123. Screenshots: screen1.png screen2.png"

Claude:
1. Runs `asc app-infos list --app-id 6736834466` → gets `appInfoId`
2. Runs `asc app-info-localizations list --app-info-id <id>` → `appName`, `tagline`
3. Runs `asc version-localizations list --version-id v123` → full `description`
4. Summarizes description → `appDescription` (2-3 sentences, ≤200 chars)
5. Reads `screen1.png`, `screen2.png` with vision → extracts `colors`, builds per-screen configs
6. Generates `ScreenPlan` JSON with 2 screens
7. Writes `app-shots-plan.json`
8. Prints generate command
