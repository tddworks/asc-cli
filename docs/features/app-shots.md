# App Shots

Create professional App Store marketing screenshots from raw app screenshots. Three approaches:

| | **Enhance** | **Compose + Enhance** | **Theme + Compose** |
|---|---|---|---|
| **What you do** | Feed a screenshot to Gemini AI | Pick a template, apply it, then enhance with AI | Pick a template + theme, AI restyles |
| **Command** | `asc app-shots generate` | `templates apply` → `generate` | `themes apply` → compose bridge |
| **AI required** | Yes (Gemini) | Yes (Gemini) | Yes (Claude via compose bridge) |
| **Control level** | Low — AI decides layout | Medium — you pick the template | High — exact layout + themed styling |

See [App Shots Themes](app-shots-themes.md) for the full theme system design.

---

## Quick Start

```bash
# 1. Save your Gemini API key (one-time)
asc app-shots config --gemini-api-key AIzaSy...

# 2. Enhance a screenshot
asc app-shots generate --file .asc/app-shots/screen-0.png

# Output: .asc/app-shots/output/screen-0.png
```

That's it. Gemini analyzes your screenshot, wraps it in a photorealistic iPhone mockup, adds marketing text, and outputs a polished App Store image.

---

## CLI Reference

### `asc app-shots generate`

Enhance a single screenshot into a marketing image using Gemini AI.

| Flag | Default | Description |
|------|---------|-------------|
| `--file` | *(required)* | Screenshot file to enhance |
| `--device-type` | — | Named device type — resizes output to exact App Store dimensions |
| `--style-reference` | — | Reference image whose visual style Gemini replicates |
| `--prompt` | — | Custom prompt (overrides the built-in auto-enhance prompt) |
| `--gemini-api-key` | — | Gemini API key (falls back to `GEMINI_API_KEY` env, then saved config) |
| `--model` | `gemini-3.1-flash-image-preview` | Gemini model |
| `--output-dir` | `.asc/app-shots/output` | Directory for generated PNGs |

```bash
# Auto-enhance — AI analyzes and designs everything
asc app-shots generate --file screen.png

# Resize to exact App Store dimensions
asc app-shots generate --file screen.png --device-type APP_IPHONE_67

# Style transfer — match another screenshot's look
asc app-shots generate --file screen.png --style-reference competitor.png

# Custom prompt — tell Gemini exactly what you want
asc app-shots generate --file screen.png \
  --prompt "Add warm glow, deepen shadows, make text pop"

# Generate multiple device sizes
asc app-shots generate --file screen.png --device-type APP_IPHONE_69 --output-dir output/69
asc app-shots generate --file screen.png --device-type APP_IPHONE_67 --output-dir output/67
asc app-shots generate --file screen.png --device-type APP_IPAD_PRO_129 --output-dir output/ipad
```

**JSON output:**
```json
{
  "generated" : ".asc/app-shots/output/screen-0.png"
}
```

**How the built-in prompt works:**

The default auto-enhance prompt tells Gemini to:
- Analyze the app screenshot (purpose, features, color scheme)
- Replace flat device frames with a photorealistic iPhone 15 Pro mockup
- Find the most compelling UI panel and "break it out" from the device with a drop shadow
- Add a bold 2-4 word ACTION VERB headline (e.g. "TRACK WEATHER") if none exists
- Apply a clean gradient background complementing the app's colors
- Add 1-2 subtle supporting elements (badges, stats)

For better results, use the **`asc-app-shots-prompt` skill** in Claude Code — it reads your screenshot, identifies exact UI panels and colors, and generates a targeted `--prompt` that names specific elements instead of letting Gemini guess.

---

### `asc app-shots templates list`

List available screenshot templates. Templates are provided by plugins (e.g. Blitz Screenshots ships 23 built-in templates).

| Flag | Default | Description |
|------|---------|-------------|
| `--size` | — | Filter by size: `portrait`, `landscape`, `portrait43`, `square` |
| `--preview` | — | Include self-contained HTML preview for each template |
| `--output` | `json` | Output format: `json`, `table`, `markdown` |
| `--pretty` | — | Pretty-print JSON |

```bash
asc app-shots templates list
asc app-shots templates list --size portrait --output table
```

**JSON output:**
```json
{
  "data": [
    {
      "id": "top-hero",
      "name": "Top Hero",
      "category": "bold",
      "supportedSizes": ["portrait"],
      "deviceCount": 1,
      "affordances": {
        "preview": "asc app-shots templates get --id top-hero --preview",
        "apply": "asc app-shots templates apply --id top-hero --screenshot screen.png",
        "detail": "asc app-shots templates get --id top-hero",
        "listAll": "asc app-shots templates list"
      }
    }
  ]
}
```

### `asc app-shots templates get`

Get details of a specific template.

| Flag | Default | Description |
|------|---------|-------------|
| `--id` | *(required)* | Template ID |
| `--preview` | — | Output self-contained HTML preview page |

```bash
asc app-shots templates get --id top-hero
asc app-shots templates get --id top-hero --preview > preview.html && open preview.html
```

### `asc app-shots templates apply`

Apply a template to a screenshot. Returns a `ScreenDesign` with affordances for next steps.

| Flag | Default | Description |
|------|---------|-------------|
| `--id` | *(required)* | Template ID |
| `--screenshot` | *(required)* | Path to screenshot file |
| `--headline` | *(required)* | Headline text |
| `--subtitle` | — | Subtitle text |
| `--tagline` | — | Tagline text (overrides template default) |
| `--app-name` | `My App` | App name |
| `--preview` | — | Preview format: `html` or `image` |
| `--image-output` | `.asc/app-shots/output/screen-0.png` | Output PNG path (for `--preview image`) |

```bash
# Get design JSON with affordances
asc app-shots templates apply \
  --id top-hero \
  --screenshot screen.png \
  --headline "Ship Faster"

# Preview as HTML in browser
asc app-shots templates apply \
  --id top-hero \
  --screenshot screen.png \
  --headline "Ship Faster" \
  --preview html > composed.html && open composed.html

# Export directly to PNG
asc app-shots templates apply \
  --id top-hero \
  --screenshot screen.png \
  --headline "Ship Faster" \
  --preview image --image-output marketing-screen.png
```

**JSON output:**
```json
{
  "data": [
    {
      "heading": "Ship Faster",
      "screenshotFile": "screen.png",
      "isComplete": true,
      "affordances": {
        "generate": "asc app-shots generate --design design.json",
        "preview": "asc app-shots templates apply --id top-hero --screenshot screen.png --headline \"Ship Faster\"",
        "changeTemplate": "asc app-shots templates list",
        "templateDetail": "asc app-shots templates get --id top-hero"
      }
    }
  ]
}
```

---

### `asc app-shots config`

Manage the stored Gemini API key.

```bash
asc app-shots config --gemini-api-key AIzaSy...   # Save
asc app-shots config                                # Show (masked)
asc app-shots config --remove                       # Delete
```

**Key resolution order:** `--gemini-api-key` flag → `$GEMINI_API_KEY` env var → `~/.asc/app-shots-config.json`

---

## Typical Workflows

### Workflow 1: Quick Enhance (simplest)

```bash
# One command — AI handles everything
asc app-shots generate --file .asc/app-shots/screen-0.png

# Resize to required App Store dimensions
asc app-shots generate --file .asc/app-shots/screen-0.png --device-type APP_IPHONE_67
```

### Workflow 2: Template + Enhance (recommended)

```bash
# 1. Browse templates
asc app-shots templates list --output table

# 2. Preview one
asc app-shots templates get --id top-hero --preview > preview.html
open preview.html

# 3. Apply to your screenshot
asc app-shots templates apply \
  --id top-hero \
  --screenshot .asc/app-shots/screen-0.png \
  --headline "Ship Faster" \
  --preview > composed.html
open composed.html

# 4. Enhance the composed result with AI
asc app-shots generate --file .asc/app-shots/output/screen-0.png --device-type APP_IPHONE_67
```

### Workflow 3: Skill-driven (Claude writes the prompt)

```bash
# In Claude Code, use the asc-app-shots-prompt skill:
# "Analyze this screenshot and generate a prompt for app-shots"
# → Claude reads the image, generates a targeted --prompt

# Then generate
asc app-shots generate --file screen.png \
  --prompt '<generated prompt>' \
  --device-type APP_IPHONE_67
```

---

## Architecture

```
ASCCommand                            Domain                              Infrastructure
+-----------------------------------+ +-----------------------------------+ +-----------------------------------+
| AppShotsCommand                   | | ScreenDesign                      | | AggregateTemplateRepository       |
|   ├── templates                   | |   index, heading, subheading      | |   (actor)                         |
|   │   ├── list  (TemplateRepo)    | |   template?, screenshotFile       | |   Aggregates TemplateProviders    |
|   │   ├── get   (TemplateRepo)    | |   isComplete, previewHTML         | +-----------------------------------+
|   │   └── apply (TemplateRepo)    | |   affordances: generate, preview  | | FileAppShotsConfigStorage         |
|   ├── generate  (Gemini direct)   | |                                   | |   ~/.asc/app-shots-config.json    |
|   └── config    (ConfigStorage)   | | ScreenshotTemplate                | +-----------------------------------+
+-----------------------------------+ |   id, name, category, background  |
                                      |   textSlots[], deviceSlots[]      |
                                      |   isPortrait, deviceCount         |
                                      |   previewHTML, affordances        |
                                      |                                   |
                                      | SlideBackground                   |
                                      |   .solid(color)                   |
                                      |   .gradient(from, to, angle)      |
                                      |                                   |
                                      | TemplateProvider (protocol)       |
                                      | TemplateRepository (protocol)     |
                                      | AppShotsConfigStorage (protocol)  |
                                      +-----------------------------------+
```

**Dependency flow:** `ASCCommand → Domain ← Infrastructure`

**Key design note:** `generate` calls the Gemini API directly via `URLSession` — no repository abstraction. This keeps the single-file enhancement path simple. When `--device-type` is specified, output is resized to exact App Store dimensions via CoreGraphics.

---

## Domain Models

### `ScreenDesign`

A single screen — knows its template, content, and how to preview itself.

| Field | Type | Description |
|-------|------|-------------|
| `index` | `Int` | Screen order (0-based) |
| `template` | `ScreenshotTemplate?` | Applied template (runtime only, excluded from Codable) |
| `screenshotFile` | `String` | Source screenshot path |
| `heading` | `String` | Main headline |
| `subheading` | `String` | Supporting text |
| `layoutMode` | `LayoutMode` | Layout hint (legacy) |
| `visualDirection` | `String` | Visual description (legacy) |
| `imagePrompt` | `String` | Per-screen Gemini prompt (legacy) |

**Computed properties:**
| Property | Type | Description |
|----------|------|-------------|
| `isComplete` | `Bool` | `template != nil && !heading.isEmpty && !screenshotFile.isEmpty` |
| `previewHTML` | `String` | Self-contained HTML preview (empty if no template) |

**Affordances** (state-aware):
| Key | When | Command |
|-----|------|---------|
| `generate` | `isComplete` | `asc app-shots generate --design design.json` |
| `preview` | `isComplete` | `asc app-shots templates apply --id {id} ...` |
| `changeTemplate` | always | `asc app-shots templates list` |
| `templateDetail` | has template | `asc app-shots templates get --id {id}` |

### `ScreenshotTemplate`

Reusable template for composing screenshots. Registered by plugins via `TemplateProvider`.

| Field | Type | Description |
|-------|------|-------------|
| `id` | `String` | Unique identifier |
| `name` | `String` | Display name |
| `category` | `TemplateCategory` | `bold`, `minimal`, `elegant`, `professional`, `playful`, `showcase`, `custom` |
| `supportedSizes` | `[ScreenSize]` | `portrait`, `landscape`, `portrait43`, `square` |
| `description` | `String` | Human-readable description |
| `background` | `SlideBackground` | `.solid(color)` or `.gradient(from, to, angle)` |
| `textSlots` | `[TemplateTextSlot]` | Text positions with role, preview, style |
| `deviceSlots` | `[TemplateDeviceSlot]` | Device positions with scale, rotation |

**Semantic booleans:** `isPortrait`, `isLandscape`, `deviceCount`

**Affordances:** `preview`, `apply`, `detail`, `listAll`

### `SlideBackground`

```swift
public enum SlideBackground: Sendable, Equatable, Codable {
    case solid(String)
    case gradient(from: String, to: String, angle: Int)
}
```

### Protocols

```swift
@Mockable
public protocol TemplateProvider: Sendable {
    var providerId: String { get }
    func templates() async throws -> [ScreenshotTemplate]
}

@Mockable
public protocol TemplateRepository: Sendable {
    func listTemplates(size: ScreenSize?) async throws -> [ScreenshotTemplate]
    func getTemplate(id: String) async throws -> ScreenshotTemplate?
}

@Mockable
public protocol AppShotsConfigStorage: Sendable {
    func load() throws -> AppShotsConfig?
    func save(_ config: AppShotsConfig) throws
    func delete() throws
}
```

---

## Device Sizes

Use `--device-type` on `generate` to resize output to exact App Store dimensions.

| Display Type | Device | Width | Height |
|---|---|---|---|
| `APP_IPHONE_69` | iPhone 6.9" | 1320 | 2868 |
| `APP_IPHONE_67` | iPhone 6.7" | 1290 | 2796 |
| `APP_IPHONE_65` | iPhone 6.5" | 1260 | 2736 |
| `APP_IPHONE_61` | iPhone 6.1" | 1179 | 2556 |
| `APP_IPHONE_58` | iPhone 5.8" | 1125 | 2436 |
| `APP_IPHONE_55` | iPhone 5.5" | 1242 | 2208 |
| `APP_IPHONE_47` | iPhone 4.7" | 750 | 1334 |
| `APP_IPAD_PRO_129` | iPad 13" | 2048 | 2732 |
| `APP_IPAD_PRO_3GEN_11` | iPad 11" | 1668 | 2388 |
| `APP_APPLE_TV` | Apple TV | 1920 | 1080 |
| `APP_DESKTOP` | Mac | 2560 | 1600 |
| `APP_APPLE_VISION_PRO` | Vision Pro | 3840 | 2160 |

---

## File Map

### Sources

```
Sources/
├── Domain/ScreenshotPlans/
│   ├── ScreenDesign.swift                  # Single screen (rich domain, carries template)
│   ├── ScreenshotTemplate.swift            # Template model + SlideBackground, TemplateCategory, ScreenSize, TextSlot, DeviceSlot
│   ├── TemplateRepository.swift            # TemplateProvider + TemplateRepository protocols
│   ├── TemplateHTMLRenderer.swift          # Renders template previews as HTML
│   ├── TemplateContent.swift               # Content to fill into a template
│   ├── AppShotsConfig.swift                # Gemini API key model
│   ├── AppShotsConfigStorage.swift         # @Mockable config storage protocol
│   └── LayoutMode.swift                    # center, left, right (legacy)
├── Infrastructure/ScreenshotPlans/
│   ├── AggregateTemplateRepository.swift   # Actor aggregating TemplateProviders
│   └── FileAppShotsConfigStorage.swift     # ~/.asc/app-shots-config.json
└── ASCCommand/Commands/AppShots/
    ├── AppShotsCommand.swift               # Entry point, registers subcommands
    ├── AppShotsGenerate.swift              # Single-file AI enhancement (direct Gemini call)
    ├── AppShotsTemplates.swift             # list, get, apply subcommands
    ├── AppShotsConfig.swift                # Gemini key management
    ├── AppShotsDisplayType.swift           # Device type enum with dimensions
    └── AppShotsUtils.swift                 # resolveGeminiApiKey(), resizeImageData()
```

### Tests

```
Tests/
├── DomainTests/ScreenshotPlans/
│   └── AppShotsConfigTests.swift
├── InfrastructureTests/ScreenshotPlans/
│   └── FileAppShotsConfigStorageTests.swift
└── ASCCommandTests/Commands/AppShots/
    ├── AppShotsGenerateTests.swift
    ├── AppShotsTemplatesTests.swift
    ├── AppShotsConfigTests.swift
    └── AppShotsDisplayTypeTests.swift
```

---

## Testing

```bash
swift test --filter 'AppShotsGenerate'              # Generate command (10)
swift test --filter 'AppShotsTemplates'              # Template commands
swift test --filter 'AppShotsDisplayType'            # Device types
swift test --filter 'AppShotsConfig'                 # Config management
swift test --filter 'AppShots'                       # All app-shots tests
```

---

## Available Templates

Templates are provided by plugins. The Blitz Screenshots plugin provides 23 built-in templates:

| Category | Templates |
|----------|-----------|
| **Bold** | Top Hero, Bold CTA, Tilted Hero, Midnight Bold |
| **Minimal** | Minimal Light, Device Only |
| **Elegant** | Dark Premium, Sage Editorial, Cream Serif, Ocean Calm, Blush Editorial |
| **Professional** | Top & Bottom, Left Aligned, Bottom Text |
| **Playful** | Warm Sunset, Sky Soft, Cartoon Peach, Cartoon Mint, Cartoon Lavender |
| **Showcase** | Duo Devices, Triple Fan, Side by Side |
| **Custom** | Custom Blank |
