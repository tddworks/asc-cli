import Foundation
import Mockable

/// A visual theme preset for App Store screenshot composition.
///
/// Themes provide AI styling directives (colors, backgrounds, floating elements, text style)
/// that are applied on top of a template layout via the compose bridge.
/// The template controls **layout** (positions); the theme controls **visual style**.
///
/// Themes are plugin-provided — each plugin (e.g. Blitz) registers its own themes
/// with its own AI provider solution. The platform ships with no built-in themes.
///
/// ## Usage
/// ```swift
/// let themes = try await repo.listThemes()
/// let context = themes[0].buildContext() // → prompt string for compose bridge
/// ```
public struct ScreenTheme: Sendable, Equatable, Identifiable, Codable {
    public let id: String
    public let name: String
    /// Emoji icon for UI display.
    public let icon: String
    public let description: String
    /// Hex color used for UI preview border/glow.
    public let accent: String
    /// CSS gradient string for theme picker preview.
    public let previewGradient: String
    /// AI styling hints that guide the compose bridge.
    public let aiHints: ThemeAIHints

    public init(
        id: String,
        name: String,
        icon: String,
        description: String,
        accent: String,
        previewGradient: String,
        aiHints: ThemeAIHints
    ) {
        self.id = id
        self.name = name
        self.icon = icon
        self.description = description
        self.accent = accent
        self.previewGradient = previewGradient
        self.aiHints = aiHints
    }
}

// MARK: - Semantic Booleans

extension ScreenTheme {
    /// Whether this theme includes floating decorative elements.
    public var hasFloatingElements: Bool { !aiHints.floatingElements.isEmpty }
}

// MARK: - Presentable

extension ScreenTheme: Presentable {
    public static var tableHeaders: [String] {
        ["ID", "Name", "Icon", "Description"]
    }
    public var tableRow: [String] {
        [id, name, icon, description]
    }
}

// MARK: - Affordances

extension ScreenTheme: AffordanceProviding {
    public var affordances: [String: String] {
        [
            "detail": "asc app-shots themes get --id \(id)",
            "listAll": "asc app-shots themes list",
            "apply": "asc app-shots themes apply --theme \(id) --template <id> --screenshot screen.png --headline \"Your Text\"",
        ]
    }
}

// MARK: - Build Context

extension ScreenTheme {
    /// Produces the theme prompt string for the compose bridge.
    ///
    /// This produces the same format as `buildThemeContext()` in blitz-compose.js,
    /// making `ScreenTheme` the single source of truth for theme definitions.
    public func buildContext() -> String {
        [
            "Visual theme: \"\(name)\" — \(description)",
            "Overall style: \(aiHints.style)",
            "Background: \(aiHints.background)",
            "Floating decorative elements to include: \(aiHints.floatingElements.joined(separator: ", "))",
            "Color palette: \(aiHints.colorPalette)",
            "Text styling: \(aiHints.textStyle)",
            "IMPORTANT: Integrate the floating elements naturally — they should enhance the design without covering the device screenshot or text. Use CSS animations (float, drift, pulse, spin) for movement. Vary sizes (small to medium) and opacity (0.15–0.7) for depth.",
        ].joined(separator: "\n")
    }


    /// Produces a prompt that instructs AI to return a `ThemeDesign` JSON object.
    ///
    /// Unlike `buildContext()` which expects full HTML back, this asks for structured
    /// JSON with normalized 0-1 positions and container-relative sizes rendered as `cqi`.
    /// The resulting `ThemeDesign` can be applied deterministically to any template fragment.
    public func buildDesignContext() -> String {
        [
            "Visual theme: \"\(name)\" — \(description)",
            "Overall style: \(aiHints.style)",
            "Background: \(aiHints.background)",
            "Floating decorative elements to include: \(aiHints.floatingElements.joined(separator: ", "))",
            "Color palette: \(aiHints.colorPalette)",
            "Text styling: \(aiHints.textStyle)",
            "",
            "Output ONLY a JSON object matching this schema (no markdown, no explanation):",
            "{",
            "  \"palette\": {\"id\": \"theme-id\", \"name\": \"Theme Name\", \"background\": \"CSS background value\", \"textColor\": \"#hex\"},",
            "  \"decorations\": [",
            "    {\"shape\": {\"label\": \"emoji or text\"}, \"x\": 0-1, \"y\": 0-1, \"size\": 0.02-0.06, \"opacity\": 0.15-0.7,",
            "     \"color\": \"#hex\", \"background\": \"css color\", \"borderRadius\": \"css value\",",
            "     \"animation\": \"float\"|\"drift\"|\"pulse\"|\"spin\"|\"twinkle\"|null}",
            "  ]",
            "}",
            "",
            "Rules:",
            "- palette.background: CSS value (e.g. \"linear-gradient(135deg, #0f172a, #7c3aed)\" or \"#1a1a2e\")",
            "- palette.textColor: hex color for text (must contrast with background)",
            "- Positions (x, y) are normalized 0-1 (0=left/top, 1=right/bottom)",
            "- Size is relative to container width (0.04 = 4% of width), rendered as cqi units",
            "- Include 4-8 decorations that match the theme",
            "- Place decorations away from center to avoid covering device screenshots or text",
            "- Use varied sizes (0.02-0.06) and opacity (0.15-0.7) for depth",
        ].joined(separator: "\n")
    }
}

// MARK: - ThemeAIHints

/// AI styling directives for a theme.
///
/// Each field guides the AI (Claude, Gemini, etc.) when restyling a deterministic template HTML.
/// Different plugins may use different AI providers to interpret these hints.
public struct ThemeAIHints: Sendable, Equatable, Codable {
    /// Overall visual direction (e.g. "cosmic and vast — deep space with luminous accents").
    public let style: String
    /// Background guidance (e.g. "deep navy-to-purple gradient suggesting a night sky").
    public let background: String
    /// Decorative elements for AI to add (e.g. ["twinkling stars", "comet trails"]).
    public let floatingElements: [String]
    /// Color palette guidance (e.g. "deep navy, indigo, bright blue, soft purple").
    public let colorPalette: String
    /// Typography guidance (e.g. "clean, modern, light on dark — slight futuristic feel").
    public let textStyle: String

    public init(
        style: String,
        background: String,
        floatingElements: [String],
        colorPalette: String,
        textStyle: String
    ) {
        self.style = style
        self.background = background
        self.floatingElements = floatingElements
        self.colorPalette = colorPalette
        self.textStyle = textStyle
    }
}

// MARK: - ThemeProvider & ThemeRepository

/// A provider that supplies visual themes.
///
/// Plugins register providers to contribute their themes to the platform.
/// Each plugin can use its own AI provider (Claude, Gemini, etc.) for styling.
@Mockable
public protocol ThemeProvider: Sendable {
    /// The unique identifier for this provider (e.g. "blitz").
    var providerId: String { get }

    /// Return all themes this provider offers.
    func themes() async throws -> [ScreenTheme]

    /// Restyle deterministic HTML with a theme using this provider's AI backend.
    ///
    /// Each plugin implements this differently:
    /// - Blitz: spawns `node compose.mjs` with `mode: "restyle"` → Claude
    /// - Others: could use Gemini, local LLM, or deterministic CSS transforms
    func compose(html: String, theme: ScreenTheme, canvasWidth: Int, canvasHeight: Int) async throws -> String

    /// Generate a `ThemeDesign` for a theme — called once, applied to all screenshots.
    ///
    /// Returns a structured design (colors, floats) that can be applied deterministically
    /// via `ThemeDesignApplier` without additional AI calls.
    func design(theme: ScreenTheme) async throws -> ThemeDesign
}

/// Default implementation: providers that don't implement `design()` yet.
extension ThemeProvider {
    public func design(theme: ScreenTheme) async throws -> ThemeDesign {
        // Fallback: compose a minimal fragment and parse the result
        // Plugins should override this with a proper `buildDesignContext()` call
        throw ThemeDesignError.notSupported
    }
}

public enum ThemeDesignError: Error, CustomStringConvertible {
    case notSupported

    public var description: String {
        switch self {
        case .notSupported: return "This theme provider does not support design generation yet"
        }
    }
}

/// Repository for querying visual themes across all providers.
@Mockable
public protocol ThemeRepository: Sendable {
    /// List all themes from all providers.
    func listThemes() async throws -> [ScreenTheme]

    /// Get a specific theme by ID (searches all providers).
    func getTheme(id: String) async throws -> ScreenTheme?

    /// Compose themed HTML — finds the provider that owns the theme and delegates to it.
    func compose(themeId: String, html: String, canvasWidth: Int, canvasHeight: Int) async throws -> String

    /// Generate a `ThemeDesign` — called once, applied to all screenshots via `ThemeDesignApplier`.
    func design(themeId: String) async throws -> ThemeDesign
}
