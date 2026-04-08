# App Shots

Create professional App Store marketing screenshots. Two modes:

| | **Gallery** | **Single Template** |
|---|---|---|
| **What you do** | Upload screenshots → pick a gallery style → all shots styled as a coordinated set | Pick a template → apply to one screenshot |
| **Output** | Hero + feature screens matching App Store gallery | One styled screenshot |
| **AI enhance** | Optional: Stage 1 CSS polish + Stage 2 Gemini photorealistic | Optional: Gemini enhance |

---

## Quick Start

```bash
# Gallery mode — all screenshots at once
asc app-shots gallery create \
  --app-name "BezelBlend" \
  --screenshots screen-0.png screen-1.png screen-2.png screen-3.png

# Single template mode — one screenshot
asc app-shots templates apply \
  --id top-hero \
  --screenshot screen-0.png \
  --headline "Ship Faster" \
  --preview html > preview.html && open preview.html
```

---

## CLI Reference

### `asc app-shots templates list`

List available single-shot templates.

| Flag | Default | Description |
|------|---------|-------------|
| `--size` | — | Filter by size: `portrait`, `landscape`, `portrait43`, `square` |
| `--output` | `json` | Output format: `json`, `table`, `markdown` |
| `--pretty` | — | Pretty-print JSON |

```bash
asc app-shots templates list
asc app-shots templates list --size portrait --output table
```

### `asc app-shots templates apply`

Apply a template to a screenshot. Returns an `AppShot` with affordances.

| Flag | Default | Description |
|------|---------|-------------|
| `--id` | *(required)* | Template ID |
| `--screenshot` | *(required)* | Path to screenshot file |
| `--headline` | *(required)* | Headline text |
| `--subtitle` | — | Body text |
| `--tagline` | — | Tagline text |
| `--preview` | — | Preview format: `html` or `image` |
| `--image-output` | `.asc/app-shots/output/screen-0.png` | Output PNG path |

```bash
# Preview as HTML
asc app-shots templates apply \
  --id top-hero --screenshot screen.png --headline "Ship Faster" \
  --preview html > composed.html && open composed.html

# Export to PNG
asc app-shots templates apply \
  --id top-hero --screenshot screen.png --headline "Ship Faster" \
  --preview image --image-output marketing.png
```

### `asc app-shots generate`

Enhance a screenshot with Gemini AI.

| Flag | Default | Description |
|------|---------|-------------|
| `--file` | *(required)* | Screenshot file to enhance |
| `--device-type` | — | Resize output to App Store dimensions |
| `--style-reference` | — | Reference image for style transfer |
| `--prompt` | — | Custom Gemini prompt |
| `--gemini-api-key` | — | API key (falls back to env/config) |

```bash
asc app-shots generate --file screen.png
asc app-shots generate --file screen.png --device-type APP_IPHONE_67
```

### `asc app-shots config`

Manage Gemini API key.

```bash
asc app-shots config --gemini-api-key AIzaSy...   # Save
asc app-shots config                                # Show
asc app-shots config --remove                       # Delete
```

---

## Architecture

```
ASCCommand                       Domain                                  Infrastructure
+------------------------------+ +--------------------------------------+ +----------------------------------+
| AppShotsCommand              | | AppShot                              | | AggregateTemplateRepository      |
|   ├── templates              | |   screenshot, headline, tagline      | |   Aggregates TemplateProviders   |
|   │   ├── list               | |   body, badges, trustMarks           | +----------------------------------+
|   │   ├── get                | |   type: .hero | .feature | .social   | | AggregateGalleryTemplateRepo     |
|   │   └── apply              | |   isConfigured, compose()            | |   Aggregates GalleryProviders    |
|   ├── gallery-templates      | |                                      | +----------------------------------+
|   │   └── list               | | Gallery                              | | FileAppShotsConfigStorage        |
|   ├── generate (Gemini)      | |   appName, appShots: [AppShot]       | |   ~/.asc/app-shots-config.json   |
|   └── config                 | |   template, palette                  | +----------------------------------+
+------------------------------+ |   renderAll(), previewHTML            |
                                  |                                      |
                                  | GalleryTemplate                      |
                                  |   screens: [ScreenType: ScreenLayout]|
                                  |   id, name, description, background  |
                                  |                                      |
                                  | ScreenLayout                       |
                                  |   headline: TextSlot                 |
                                  |   devices: [DeviceSlot]              |
                                  |   decorations: [Decoration]          |
                                  |                                      |
                                  | GalleryPalette                       |
                                  |   id, name, background (CSS)         |
                                  |                                      |
                                  | AppShotTemplate                   |
                                  |   screenLayout + palette            |
                                  |   category, supportedSizes           |
                                  |                                      |
                                  | GalleryHTMLRenderer                  |
                                  |   renderScreen() — one renderer      |
                                  |   renderPreviewPage()                |
                                  |   wrapPage()                         |
                                  +--------------------------------------+
```

**Dependency flow:** `ASCCommand → Domain ← Infrastructure`

**Unified rendering:** Everything renders through `GalleryHTMLRenderer.renderScreen()`. Both `Gallery.renderAll()` and `AppShotTemplate.apply()` delegate to it.

---

## Domain Models

### `AppShot`

A single designed App Store screenshot — the core content unit.

| Field | Type | Description |
|-------|------|-------------|
| `screenshot` | `String` | Source screenshot file path |
| `type` | `ScreenType` | `.hero`, `.feature`, `.social` |
| `headline` | `String?` | Main headline text |
| `tagline` | `String?` | Small caps text above headline |
| `body` | `String?` | Description paragraph below headline |
| `badges` | `[String]` | Feature badge pills (e.g. "iPhone 17", "Mesh") |
| `trustMarks` | `[String]?` | Trust badges (hero only, e.g. "4.9 STARS") |

**Computed:** `isConfigured` (has headline), `isHero`, `isStandalone`

**Key method:** `compose(screenLayout:, palette:) → String` — renders HTML

### `Gallery`

A coordinated set of App Store screenshots. Created from screenshot files, first becomes hero.

| Field | Type | Description |
|-------|------|-------------|
| `appName` | `String` | App name |
| `appShots` | `[AppShot]` | Screenshots with content (first = hero) |
| `template` | `GalleryTemplate?` | Layout per screen type |
| `palette` | `GalleryPalette?` | Color scheme |

**Computed:** `isReady`, `readiness`, `shotCount`, `heroShot`, `unconfiguredShots`, `previewHTML`

**Key method:** `renderAll() → [String]` — renders all configured shots

**Codable:** Gallery serializes to/from JSON. `gallery-templates.json` is `[Gallery]`.

### `GalleryTemplate`

Layout rules per screen type. A gallery template defines WHERE things go.

| Field | Type | Description |
|-------|------|-------------|
| `id` | `String` | Unique identifier |
| `name` | `String` | Display name |
| `description` | `String` | Human-readable description |
| `background` | `String` | CSS background (shared by all screens) |
| `screens` | `[ScreenType: ScreenLayout]` | Layout per type |

### `ScreenLayout`

Layout for one screen type. Supports single, side-by-side, and triple-fan device arrangements.

| Field | Type | Description |
|-------|------|-------------|
| `headline` | `TextSlot` | Text position and style |
| `devices` | `[DeviceSlot]` | Device positions (empty = no device) |
| `decorations` | `[Decoration]` | Ambient shapes |

### `GalleryPalette`

Color scheme — HOW things look.

| Field | Type | Description |
|-------|------|-------------|
| `id` | `String` | Identifier |
| `name` | `String` | Display name |
| `background` | `String` | CSS background value |

### `AppShotTemplate`

Convenience wrapper for single-shot templates. Wraps `ScreenLayout` + `GalleryPalette` with filter metadata.

| Field | Type | Description |
|-------|------|-------------|
| `screenLayout` | `ScreenLayout` | Layout |
| `palette` | `GalleryPalette` | Colors |
| `category` | `TemplateCategory` | `bold`, `minimal`, `elegant`, etc. |
| `supportedSizes` | `[ScreenSize]` | `portrait`, `landscape`, etc. |

### Supporting Types

```swift
public struct TextSlot { y, size, weight, align }
public struct DeviceSlot { x, y, width }
public struct Decoration { shape, x, y, size, opacity }
public enum DecorationShape { gem, orb, sparkle, arrow }
public enum ScreenType { hero, feature, social }
public enum TemplateCategory { bold, minimal, elegant, professional, playful, showcase, custom }
public enum ScreenSize { portrait, portrait43, landscape, square }
```

### Protocols

```swift
@Mockable protocol TemplateProvider { func templates() async throws -> [AppShotTemplate] }
@Mockable protocol TemplateRepository { func listTemplates(size:) ... ; func getTemplate(id:) ... }
@Mockable protocol GalleryTemplateProvider { func galleries() async throws -> [Gallery] }
@Mockable protocol GalleryTemplateRepository { func listGalleries() ... ; func getGallery(templateId:) ... }
```

---

## File Map

### Sources

```
Sources/
├── Domain/ScreenshotPlans/
│   ├── Gallery/
│   │   ├── AppShot.swift                    # Content unit (headline, badges, trustMarks)
│   │   ├── Gallery.swift                    # Aggregate (appShots + template + palette)
│   │   ├── GalleryTemplate.swift            # Per-screen-type layouts
│   │   ├── GalleryPalette.swift             # Color scheme
│   │   ├── ScreenLayout.swift             # TextSlot, DeviceSlot, Decoration
│   │   ├── GalleryHTMLRenderer.swift        # Unified renderer (renderScreen, wrapPage)
│   │   └── GalleryTemplateRepository.swift  # Provider + Repository protocols
│   ├── AppShotTemplate.swift             # Single-shot template (wraps ScreenLayout + Palette)
│   ├── TemplateRepository.swift             # Single template protocols
│   ├── ScreenTheme.swift                    # AI theme hints
│   ├── ThemedPage.swift                     # Themed HTML page wrapper
│   ├── AppShotsConfig.swift                 # Gemini API key model
│   └── AppShotsConfigStorage.swift          # Config storage protocol
├── Infrastructure/ScreenshotPlans/
│   ├── AggregateTemplateRepository.swift    # Single template aggregator
│   ├── AggregateGalleryTemplateRepository.swift  # Gallery aggregator
│   └── FileAppShotsConfigStorage.swift      # ~/.asc/app-shots-config.json
└── ASCCommand/Commands/AppShots/
    ├── AppShotsCommand.swift                # Entry point
    ├── AppShotsGenerate.swift               # Gemini AI enhancement
    ├── AppShotsTemplates.swift              # list, get, apply
    ├── AppShotsConfig.swift                 # Key management
    ├── AppShotsDisplayType.swift            # Device dimensions
    └── AppShotsExport.swift                 # HTML → PNG rendering
```

### Tests

```
Tests/
├── DomainTests/ScreenshotPlans/
│   ├── Gallery/
│   │   ├── AppShotTests.swift               # 11 tests
│   │   ├── GalleryTests.swift               # 11 tests
│   │   ├── GalleryComposeTests.swift        # 8 tests
│   │   ├── GalleryCodableTests.swift        # 10 tests
│   │   ├── GalleryPreviewTests.swift        # 4 tests
│   │   ├── GalleryPreviewOutputTests.swift  # 1 test (visual verification)
│   │   ├── ScreenLayoutTests.swift        # 6 tests
│   │   └── GalleryTemplateRepositoryTests.swift  # 3 tests
│   ├── AppShotTemplateTests.swift        # 8 tests
│   ├── TemplateApplyTests.swift
│   └── TemplateRenderTests.swift
└── ASCCommandTests/Commands/AppShots/
    ├── AppShotsTemplatesTests.swift
    └── AppShotsGenerateTests.swift
```

---

## Testing

```bash
swift test --filter 'AppShotTests'              # AppShot domain (11)
swift test --filter 'GalleryTests'              # Gallery domain (11)
swift test --filter 'GalleryComposeTests'       # Compose flow (8)
swift test --filter 'GalleryCodableTests'       # JSON round-trip (10)
swift test --filter 'AppShotTemplateTests'   # Single template (8)
swift test --filter 'AppShots'                  # All app-shots tests
```
