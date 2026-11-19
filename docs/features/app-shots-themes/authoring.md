# Adding themes from a plugin

Themes are registered by plugins through `ThemeProvider`. The platform handles discovery (`themes list`), lookup (`themes get`), and delegation (`themes apply`, `themes design`); the plugin provides the theme data and the AI logic.

```swift
@Mockable
public protocol ThemeProvider: Sendable {
    var providerId: String { get }
    func themes() async throws -> [ScreenTheme]
    func compose(html: String, theme: ScreenTheme, canvasWidth: Int, canvasHeight: Int) async throws -> String
    func design(theme: ScreenTheme) async throws -> ThemeDesign  // generate once, apply many
}
```

- `compose` receives the deterministic template HTML and must return restyled HTML. It should keep all text content and positions and the device `<img>` positioning; change the background and text colors; add floating decorative elements with CSS `@keyframes` animations.
- `design` returns a `ThemeDesign` (a `GalleryPalette` with `background` + optional `textColor`, plus `[Decoration]`), which the CLI applies to every slide without further AI calls.
- `theme.buildContext()` produces the prompt for `compose`; `buildDesignContext()` produces a prompt asking for `ThemeDesign` JSON. `asc app-shots themes get --id <id> --context` prints the former.

```swift
struct MyThemeProvider: ThemeProvider {
    var providerId: String { "my-plugin" }

    func themes() async throws -> [ScreenTheme] {
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
        // Call your AI backend with theme.buildContext() and return the restyled HTML
    }
}

// Register at plugin startup:
await AggregateThemes.shared.register(provider: MyThemeProvider())
```

`AggregateThemes` finds which provider owns the requested theme and delegates `compose()` / `design()` to it.

For an example of the prompt `buildContext()` produces, for a "Space" theme:

```
Visual theme: "Space" — Cosmic backgrounds, twinkling stars, nebula colors
Overall style: cosmic and vast — deep space with luminous accents
Background: deep navy-to-purple gradient suggesting a night sky or nebula
Floating decorative elements to include: twinkling stars (varying sizes), small planets, comet trails, nebula wisps, constellation dots
Color palette: deep navy, indigo, bright blue, soft purple, white star highlights
Text styling: clean, modern, light on dark — slight futuristic feel
IMPORTANT: Integrate the floating elements naturally — they should enhance the design without covering the device screenshot or text. Use CSS animations (float, drift, pulse, spin) for movement. Vary sizes (small to medium) and opacity (0.15–0.7) for depth.
```

See also: [App Shots Themes](README.md) · [Plugins](../plugins/README.md)
