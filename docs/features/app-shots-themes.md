# App Shots Themes

Visual theme presets for App Store screenshot composition. Themes control colors, backgrounds, floating decorative elements, and text styling — applied on top of a template layout via AI.

Themes are **plugin-provided** — each plugin registers its own themes with its own AI provider solution. The platform ships with no built-in themes. This allows different plugins to offer different themes with different AI backends.

## The Problem

1. **Layout drift**: When AI generates screenshots from a text description of the template layout, it approximates positions instead of preserving the exact template layout.
2. **No domain model**: Themes have no platform-level representation — invisible to the CLI and agents.
3. **Coupled to one AI provider**: Theme logic is tied to a single plugin implementation.

## Solution: Two-Step Compose + Plugin-Provided Themes

### Core Insight

Separate **layout** (deterministic) from **styling** (AI-driven):

1. **Step 1 — Deterministic HTML**: Render the template using `TemplateHTMLRenderer` → exact pixel-perfect layout
2. **Step 2 — AI Restyle**: Send that HTML + theme context to the plugin's AI provider → restyles while **preserving all positions**

Themes live in Domain as a data model (`ScreenTheme` + `ThemeAIHints`), registered by plugins via `ThemeProvider` (same pattern as `TemplateProvider`).

---

## User Journey

### Plugin UI

```
Capture → Design (pick template) → Compose (pick theme → Auto-Compose) → Export
```

1. User captures screenshots
2. User picks a template (defines layout: text slots, device slots)
3. User picks a theme (visual style)
4. Auto-Compose:
   - `TemplateHTMLRenderer.render(template, content)` → deterministic HTML
   - Send HTML + `ScreenTheme.buildContext()` to plugin's AI provider → restyles
   - Result: themed HTML with exact template layout preserved
5. Export PNGs

### CLI / Agent

```bash
# 1. Browse templates
asc app-shots templates list

# 2. Browse themes (plugin-provided)
asc app-shots themes list

# 3. Get theme detail or AI prompt
asc app-shots themes get --id space --pretty
asc app-shots themes get --id space --context  # outputs buildContext() string

# 4. Apply theme (two-step: deterministic HTML → AI restyle)
asc app-shots themes apply --theme space --template top-hero --screenshot screen.png --headline "Ship Faster"
```

---

## CLI Reference

### `asc app-shots themes list`

List all available themes from registered plugins.

| Flag | Default | Description |
|------|---------|-------------|
| `--output` | `json` | Output format: `json`, `table`, `markdown` |
| `--pretty` | — | Pretty-print JSON |

```bash
asc app-shots themes list
asc app-shots themes list --output table
```

**JSON output:**
```json
{
  "data": [
    {
      "id": "space",
      "name": "Space",
      "icon": "🚀",
      "description": "Cosmic backgrounds, twinkling stars, nebula colors",
      "accent": "#3b82f6",
      "aiHints": {
        "style": "cosmic and vast — deep space with luminous accents",
        "background": "deep navy-to-purple gradient suggesting a night sky or nebula",
        "floatingElements": ["twinkling stars (varying sizes)", "small planets", "comet trails"],
        "colorPalette": "deep navy, indigo, bright blue, soft purple, white star highlights",
        "textStyle": "clean, modern, light on dark — slight futuristic feel"
      },
      "affordances": {
        "detail": "asc app-shots themes get --id space",
        "listAll": "asc app-shots themes list",
        "apply": "asc app-shots themes apply --theme space --template <id> --screenshot screen.png --headline \"Your Text\""
      }
    }
  ]
}
```

### `asc app-shots themes get`

Get details of a specific theme.

| Flag | Default | Description |
|------|---------|-------------|
| `--id` | *(required)* | Theme ID |
| `--context` | — | Output `buildContext()` prompt string instead of JSON |
| `--output` | `json` | Output format |
| `--pretty` | — | Pretty-print JSON |

```bash
asc app-shots themes get --id neon --pretty
asc app-shots themes get --id space --context  # outputs AI prompt
```

### `asc app-shots themes apply` *(planned)*

Apply a theme to a template+screenshot composition. Two-step process:
1. Renders deterministic HTML from template layout
2. Delegates to the plugin's `ThemeProvider.compose()` → AI restyles

| Flag | Default | Description |
|------|---------|-------------|
| `--theme` | *(required)* | Theme ID |
| `--template` | *(required)* | Template ID |
| `--screenshot` | *(required)* | Path to screenshot file |
| `--headline` | `Your Headline` | Headline text |
| `--subtitle` | — | Optional subtitle text |
| `--app-name` | `My App` | App name for context |

```bash
asc app-shots themes apply \
  --theme space \
  --template top-hero \
  --screenshot .asc/app-shots/screen-0.png \
  --headline "Ship Faster"
```

---

## Architecture

```
Domain                                Infrastructure                   ASCCommand
┌─────────────────────────────┐      ┌──────────────────────────┐     ┌─────────────────┐
│ ScreenTheme                 │      │ AggregateThemeRepository │     │ themes list     │
│   id, name, icon, desc      │      │   (actor, shared)        │     │ themes get      │
│   accent, previewGradient   │      │   register(provider:)    │     │ themes apply    │
│   aiHints: ThemeAIHints     │      │   listThemes()           │     └────────┬────────┘
│   buildContext() → String   │      │   getTheme(id:)          │              │
│   AffordanceProviding       │      │   compose(id:html:...)   │              │
├─────────────────────────────┤      └──────────────────────────┘              ▼
│ ThemeAIHints                │                ▲                        ClientProvider
│   style, background         │                │                       makeThemeRepository()
│   floatingElements          │      ┌─────────────────────┐
│   colorPalette, textStyle   │      │ ThemeProvider        │◀── Plugin A (e.g. Claude)
├─────────────────────────────┤      │  providerId          │◀── Plugin B (e.g. Gemini)
│ ThemeProvider (protocol)    │      │  themes()            │
│   providerId: String        │      │  compose(html:...)   │ ← each plugin owns its AI
│   themes() → [ScreenTheme]  │      └─────────────────────┘
│   compose(html:theme:...)   │
│     → String (themed HTML)  │
├─────────────────────────────┤
│ ThemeRepository (protocol)  │
│   listThemes()              │
│   getTheme(id:)             │
│   compose(themeId:html:...) │
└─────────────────────────────┘
```

### Plugin Compose Ownership

Each `ThemeProvider` owns its AI compose capability. When `themes apply` is called:

1. `AggregateThemeRepository` finds which provider owns the requested theme
2. Delegates `compose()` to that provider
3. The provider calls its own AI backend

This means:
- Each plugin can use any AI provider (Claude, Gemini, local LLM, deterministic CSS transforms)
- `asc app-shots themes apply` works with any plugin's AI backend transparently
- Plugins are the single source of truth for both theme data and compose logic

### Two-Step Compose Flow

**Step 1 — Deterministic HTML** (no AI):
```
ScreenshotTemplate + TemplateContent
        │
        ▼
TemplateHTMLRenderer.render(template, content)
        │
        ▼
HTML with exact positions:
  - Text at template's x/y/fontSize
  - Device at template's x/y/scale/rotation
  - Template's background colors
  - No floating elements
```

**Step 2 — AI Restyle** (plugin's AI provider):
```
Deterministic HTML + ScreenTheme.buildContext()
        │
        ▼
ThemeProvider.compose(html:theme:canvas:)
        │
        ▼
AI generates:
  - KEEPS all text content and positions
  - KEEPS device <img> positioning
  - CHANGES background to theme colors
  - CHANGES text colors for contrast
  - ADDS 4-8 floating decorative elements
  - ADDS CSS @keyframes animations
```

**No theme selected**: Skip step 2, use deterministic HTML as-is.

---

## Domain Models

### `ScreenTheme`

```swift
public struct ScreenTheme: Sendable, Equatable, Identifiable, Codable {
    public let id: String
    public let name: String
    public let icon: String           // emoji for UI
    public let description: String
    public let accent: String         // hex color for UI preview border
    public let previewGradient: String // CSS gradient for theme picker
    public let aiHints: ThemeAIHints  // AI styling directives (always present)
}
```

**Computed properties:**

| Property | Type | Description |
|----------|------|-------------|
| `hasFloatingElements` | `Bool` | Theme includes floating decorative elements |

**Key methods:**

| Method | Returns | Description |
|--------|---------|-------------|
| `buildContext()` | `String` | Produces the theme prompt for the plugin's AI provider |

**Affordances:**

| Key | Command |
|-----|---------|
| `detail` | `asc app-shots themes get --id {id}` |
| `listAll` | `asc app-shots themes list` |
| `apply` | `asc app-shots themes apply --theme {id} --template <id> --screenshot screen.png --headline "Your Text"` |

### `ThemeAIHints`

```swift
public struct ThemeAIHints: Sendable, Equatable, Codable {
    public let style: String            // overall visual direction
    public let background: String       // background guidance
    public let floatingElements: [String] // decorative elements for AI to add
    public let colorPalette: String     // color guidance
    public let textStyle: String        // typography guidance
}
```

### `ThemeProvider` / `ThemeRepository` (protocols)

```swift
@Mockable
public protocol ThemeProvider: Sendable {
    var providerId: String { get }
    func themes() async throws -> [ScreenTheme]
    /// Restyle deterministic HTML with a theme using this provider's AI backend.
    func compose(html: String, theme: ScreenTheme, canvasWidth: Int, canvasHeight: Int) async throws -> String
}

@Mockable
public protocol ThemeRepository: Sendable {
    func listThemes() async throws -> [ScreenTheme]
    func getTheme(id: String) async throws -> ScreenTheme?
    /// Compose themed HTML — delegates to the provider that owns the theme.
    func compose(themeId: String, html: String, canvasWidth: Int, canvasHeight: Int) async throws -> String
}
```

### `buildContext()` Output

For a "Space" theme, `buildContext()` produces:

```
Visual theme: "Space" — Cosmic backgrounds, twinkling stars, nebula colors
Overall style: cosmic and vast — deep space with luminous accents
Background: deep navy-to-purple gradient suggesting a night sky or nebula
Floating decorative elements to include: twinkling stars (varying sizes), small planets, comet trails, nebula wisps, constellation dots
Color palette: deep navy, indigo, bright blue, soft purple, white star highlights
Text styling: clean, modern, light on dark — slight futuristic feel
IMPORTANT: Integrate the floating elements naturally — they should enhance the design without covering the device screenshot or text. Use CSS animations (float, drift, pulse, spin) for movement. Vary sizes (small to medium) and opacity (0.15–0.7) for depth.
```

---

## File Map

### New Files

| File | Purpose |
|------|---------|
| `Sources/Domain/ScreenshotPlans/ScreenTheme.swift` | `ScreenTheme` + `ThemeAIHints` + `ThemeProvider` + `ThemeRepository` + affordances + `buildContext()` |
| `Sources/Infrastructure/ScreenshotPlans/AggregateThemeRepository.swift` | Actor that aggregates themes from all registered providers |
| `Sources/ASCCommand/Commands/AppShots/AppShotsThemes.swift` | `themes list` / `get` commands |
| `Tests/DomainTests/ScreenshotPlans/ScreenThemeTests.swift` | Domain model tests |
| `Tests/InfrastructureTests/ScreenshotPlans/AggregateThemeRepositoryTests.swift` | Repository aggregation + compose delegation tests |
| `Tests/ASCCommandTests/Commands/AppShots/AppShotsThemesTests.swift` | Command tests |

### Modified Files

| File | Change |
|------|--------|
| `Sources/ASCCommand/Commands/AppShots/AppShotsCommand.swift` | Register `AppShotsThemesCommand` in subcommands |
| `Sources/ASCCommand/ClientProvider.swift` | Add `makeThemeRepository()` |

---

## Testing

```bash
swift test --filter 'ScreenThemeTests'                  # Domain (8 tests)
swift test --filter 'AggregateThemeRepositoryTests'     # Infrastructure (7 tests)
swift test --filter 'AppShotsThemesTests'               # Commands (5 tests)
swift test --filter 'AppShots'                          # All app-shots tests
```

---

## Plugin Integration Guide

To add themes to a plugin, implement `ThemeProvider`:

```swift
struct MyThemeProvider: ThemeProvider {
    var providerId: String { "my-plugin" }

    func themes() async throws -> [ScreenTheme] {
        // Return your theme definitions
        [
            ScreenTheme(
                id: "my-theme", name: "My Theme", icon: "🎯",
                description: "Custom theme with unique styling",
                accent: "#ff5500",
                previewGradient: "linear-gradient(135deg, #ff5500, #ff8800)",
                aiHints: ThemeAIHints(
                    style: "vibrant and energetic",
                    background: "warm gradient from orange to coral",
                    floatingElements: ["sparkles", "geometric shapes"],
                    colorPalette: "orange, coral, warm white",
                    textStyle: "bold, modern sans-serif"
                )
            )
        ]
    }

    func compose(html: String, theme: ScreenTheme, canvasWidth: Int, canvasHeight: Int) async throws -> String {
        // Call your AI backend to restyle the HTML
        // html = deterministic template HTML from TemplateHTMLRenderer
        // theme.buildContext() = AI prompt with styling directives
        // Return: restyled HTML with theme applied
    }
}

// Register at plugin startup:
await AggregateThemeRepository.shared.register(provider: MyThemeProvider())
```

The platform handles discovery (`themes list`), lookup (`themes get`), and compose delegation (`themes apply`) — the plugin just provides data and AI logic.
