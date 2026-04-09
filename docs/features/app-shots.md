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

### `asc app-shots gallery-templates list`

List gallery templates (multi-screen sets with sample content).

| Flag | Default | Description |
|------|---------|-------------|
| `--output` | `json` | Output format: `json`, `table`, `markdown` |
| `--pretty` | — | Pretty-print JSON |

```bash
asc app-shots gallery-templates list
asc app-shots gallery-templates list --output table
```

### `asc app-shots gallery-templates get`

Get a specific gallery template.

| Flag | Default | Description |
|------|---------|-------------|
| `--id` | *(required)* | Gallery template ID |
| `--preview` | — | Output self-contained HTML gallery preview page |

```bash
asc app-shots gallery-templates get --id neon-pop --pretty
asc app-shots gallery-templates get --id neon-pop --preview > preview.html && open preview.html
```

### `asc app-shots themes design`

Generate a ThemeDesign (palette + decorations) from AI — one call, reusable across slides.

| Flag | Default | Description |
|------|---------|-------------|
| `--id` | *(required)* | Theme ID |

```bash
asc app-shots themes design --id luxury > design.json
```

### `asc app-shots themes apply-design`

Apply a cached ThemeDesign deterministically — no AI call.

| Flag | Default | Description |
|------|---------|-------------|
| `--design` | *(required)* | Path to ThemeDesign JSON file |
| `--template` | *(required)* | Template ID |
| `--screenshot` | *(required)* | Path to screenshot file |
| `--headline` | `Your Headline` | Headline text |
| `--preview` | — | Preview format: `html` or `image` |
| `--image-output` | `.asc/app-shots/output/screen-0.png` | Output PNG path |

```bash
# Two-step workflow: generate once, apply many
asc app-shots themes design --id luxury > design.json
asc app-shots themes apply-design --design design.json \
  --template top-hero --screenshot screen.png --headline "Ship Faster" \
  --preview html > themed.html
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
                                  |   renderScreen() — context builder   |
                                  |   renderPreviewPage()                |
                                  |   wrapPage()                         |
                                  |   cachedPreview() — preview cache    |
                                  |                                      |
                                  | HTMLComposer (Mustache)              |
                                  |   render(template:, with:)           |
                                  |   Pre-compiled MustacheLibrary       |
                                  |                                      |
                                  | .mustache templates (Resources/)     |
                                  |   screen, wireframe, page-wrapper    |
                                  |   theme-vars, keyframes, preview-*   |
                                  +--------------------------------------+
```

**Dependency flow:** `ASCCommand → Domain ← Infrastructure`

**Unified rendering:** Everything renders through `GalleryHTMLRenderer.renderScreen()`. Both `Gallery.renderAll()` and `AppShotTemplate.apply()` delegate to it.

### Responsive Sizing (`cqi` Units)

All text and element sizing uses CSS Container Query Inline-size (`cqi`) units. This ensures consistent proportions between preview (320px container) and export (full viewport).

```
1cqi = 1% of the container's inline size
```

`GalleryHTMLRenderer` builds context dictionaries from domain models and delegates all HTML rendering to Mustache templates:

| Entry Point | Template | Purpose |
|-------------|----------|---------|
| `renderScreen()` | `screen.mustache` | Full screen: text, devices, badges, decorations |
| `wrapPage()` | `page-wrapper.mustache` | HTML document wrapper |
| `renderPreviewPage()` | `preview-page.mustache` + `preview-screen.mustache` | Gallery preview strip |
| (inline) | `wireframe.mustache` | Phone wireframe mockup |
| (inline) | `theme-vars.mustache` | CSS custom properties for light/dark themes |
| (inline) | `keyframes.mustache` | CSS animation keyframes |

**SRP:** The renderer only builds data contexts — zero HTML, zero colors, zero CSS. All presentation lives in `.mustache` templates. Color scheme (light/dark) is handled by CSS custom properties in `theme-vars.mustache`.

### Mustache Template System

Templates use [swift-mustache](https://github.com/hummingbird-project/swift-mustache) (from Hummingbird). All templates are pre-compiled into a `MustacheLibrary` at startup for fast rendering.

```swift
// Named template rendering (pre-compiled)
HTMLComposer.render(template: "screen", with: context)

// Inline template rendering
HTMLComposer.render("Hello {{name}}!", with: ["name": "World"])
// → "Hello World!"

// Replace the template library (e.g. from a plugin)
HTMLComposer.setLibrary(customLibrary)
```

Standard Mustache syntax: `{{var}}`, `{{{raw}}}`, `{{#section}}...{{/section}}`, `{{^inverted}}...{{/inverted}}`.

### Verification

```bash
# Preview a template as HTML — open in browser to visually verify
asc app-shots templates apply --id top-hero --screenshot screen.png --headline "Test" \
  --preview html > preview.html && open preview.html

# Export to PNG and verify sizing consistency
asc app-shots templates apply --id top-hero --screenshot screen.png --headline "Test" \
  --preview image --image-output export.png
```

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

Layout for one screen type. Supports tagline/headline/subheading text slots, single/side-by-side/triple-fan device arrangements.

| Field | Type | Description |
|-------|------|-------------|
| `tagline` | `TextSlot?` | Small caps text above headline |
| `headline` | `TextSlot` | Main headline position and style |
| `subheading` | `TextSlot?` | Supporting text below headline |
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
public struct TextSlot { y, size, weight, align, preview? }
public struct DeviceSlot { x, y, width }
public struct Decoration { shape, x, y, size, opacity, color?, background?, borderRadius?, animation? }
public enum DecorationShape { gem, orb, sparkle, arrow, label(String) }  // .displayCharacter computed property
public enum DecorationAnimation { float, drift, pulse, spin, twinkle }
public enum ScreenType { hero, feature, social }
public enum TemplateCategory { bold, minimal, elegant, professional, playful, showcase, custom }
public enum ScreenSize { portrait, portrait43, landscape, square }
```

### `GalleryPalette` — Derived Colors

`GalleryPalette` owns theme detection and derived text colors:

```swift
palette.isLight        // heuristic from background hex values
palette.headlineColor  // explicit textColor or auto-detected from isLight
```

### `HTMLComposer` (Mustache)

Wraps `MustacheLibrary` from [swift-mustache](https://github.com/hummingbird-project/swift-mustache). Templates are pre-compiled at startup.

```swift
// Named template (pre-compiled, fast)
HTMLComposer.render(template: "screen", with: context)

// Inline template
HTMLComposer.render("Hello {{name}}!", with: ["name": "World"])
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
├── Domain/Screenshots/
│   ├── Gallery/
│   │   ├── AppShot.swift                    # Content unit (headline, badges, trustMarks)
│   │   ├── Gallery.swift                    # Aggregate (appShots + template + palette)
│   │   ├── GalleryTemplate.swift            # Per-screen-type layouts
│   │   ├── GalleryPalette.swift             # Color scheme
│   │   ├── ScreenLayout.swift             # TextSlot, DeviceSlot, Decoration
│   │   ├── GalleryHTMLRenderer.swift        # Context builder → Mustache templates (renderScreen, wrapPage)
│   │   ├── HTMLComposer.swift               # Mustache wrapper (MustacheLibrary, cached compilation)
│   │   ├── GalleryTemplateRepository.swift  # Provider + Repository protocols
│   │   └── Resources/                      # Mustache template files
│   │       ├── screen.mustache              #   Full screen: text, devices, badges, decorations
│   │       ├── wireframe.mustache           #   Phone wireframe mockup (CSS vars)
│   │       ├── theme-vars.mustache          #   CSS custom properties for light/dark themes
│   │       ├── keyframes.mustache           #   CSS animation keyframes
│   │       ├── page-wrapper.mustache        #   Full HTML document wrapper
│   │       ├── preview-page.mustache        #   Gallery preview page
│   │       └── preview-screen.mustache      #   Preview screen card
│   ├── AppShotTemplate.swift             # Single-shot template (wraps ScreenLayout + Palette)
│   ├── TemplateRepository.swift             # Single template protocols
│   ├── ScreenTheme.swift                    # AI theme hints + buildDesignContext()
│   ├── ThemeDesign.swift                    # ThemeDesign + ThemeBackground + ThemeFloat
│   ├── ThemeDesignApplier.swift             # Deterministic theme applier (cqi units)
│   ├── ThemedPage.swift                     # Themed HTML page wrapper
│   ├── AppShotsConfig.swift                 # Gemini API key model
│   └── AppShotsConfigStorage.swift          # Config storage protocol
├── Infrastructure/Screenshots/
│   ├── AggregateTemplateRepository.swift    # Single template aggregator
│   ├── AggregateGalleryTemplateRepository.swift  # Gallery aggregator
│   └── FileAppShotsConfigStorage.swift      # ~/.asc/app-shots-config.json
└── ASCCommand/Commands/AppShots/
    ├── AppShotsCommand.swift                # Entry point
    ├── AppShotsTemplates.swift              # templates: list, get, apply
    ├── AppShotsGalleryTemplates.swift       # gallery-templates: list, get
    ├── AppShotsThemes.swift                 # themes: list, get, design, apply-design, apply
    ├── AppShotsGenerate.swift               # Gemini AI enhancement
    ├── AppShotsConfig.swift                 # Key management
    ├── AppShotsDisplayType.swift            # Device dimensions
    └── AppShotsExport.swift                 # HTML → PNG rendering
```

### Tests

```
Tests/
├── DomainTests/Screenshots/
│   ├── Gallery/
│   │   ├── AppShotTests.swift               # 11 tests
│   │   ├── GalleryTests.swift               # 11 tests
│   │   ├── GalleryComposeTests.swift        # 8 tests
│   │   ├── GalleryCodableTests.swift        # 10 tests
│   │   ├── GalleryPreviewTests.swift        # 4 tests
│   │   ├── GalleryPreviewOutputTests.swift  # 1 test (visual verification)
│   │   ├── ScreenLayoutTests.swift        # 6 tests
│   │   └── GalleryTemplateRepositoryTests.swift  # 3 tests
│   │   ├── GalleryHTMLRendererTests.swift    # 15 tests (Mustache-backed rendering)
│   │   └── HTMLComposerTests.swift          # 19 tests (Mustache wrapper)
│   ├── AppShotTemplateTests.swift        # 8 tests
│   ├── ThemeDesignTests.swift               # 9 tests
│   ├── ThemeDesignApplierTests.swift        # 10 tests
│   ├── TemplateApplyTests.swift
│   └── TemplateRenderTests.swift
└── ASCCommandTests/Commands/AppShots/
    ├── AppShotsTemplatesTests.swift
    ├── AppShotsThemesTests.swift            # 11 tests
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
swift test --filter 'HTMLComposerTests'           # Mustache wrapper (19)
swift test --filter 'GalleryHTMLRendererTests'    # Mustache-backed renderer (15)
swift test --filter 'AppShots'                    # All app-shots tests
```
