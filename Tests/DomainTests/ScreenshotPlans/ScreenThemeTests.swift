import Foundation
import Testing
@testable import Domain

@Suite("ScreenTheme")
struct ScreenThemeTests {

    // MARK: - Helpers

    private func makeTheme(
        id: String = "space",
        name: String = "Space",
        icon: String = "🚀",
        description: String = "Cosmic backgrounds, twinkling stars, nebula colors",
        accent: String = "#3b82f6",
        previewGradient: String = "linear-gradient(135deg, #0f172a, #1e40af, #7c3aed)",
        aiHints: ThemeAIHints = ThemeAIHints(
            style: "cosmic and vast — deep space with luminous accents",
            background: "deep navy-to-purple gradient suggesting a night sky or nebula",
            floatingElements: ["twinkling stars (varying sizes)", "small planets", "comet trails", "nebula wisps", "constellation dots"],
            colorPalette: "deep navy, indigo, bright blue, soft purple, white star highlights",
            textStyle: "clean, modern, light on dark — slight futuristic feel"
        )
    ) -> ScreenTheme {
        ScreenTheme(
            id: id, name: name, icon: icon, description: description,
            accent: accent, previewGradient: previewGradient, aiHints: aiHints
        )
    }

    // MARK: - Model

    @Test func `theme has id name and icon`() {
        let theme = makeTheme()
        #expect(theme.id == "space")
        #expect(theme.name == "Space")
        #expect(theme.icon == "🚀")
    }

    @Test func `theme has floating elements when hints include them`() {
        let theme = makeTheme()
        #expect(theme.hasFloatingElements)
    }

    @Test func `theme has no floating elements when hints list is empty`() {
        let theme = makeTheme(aiHints: ThemeAIHints(
            style: "minimal", background: "white", floatingElements: [],
            colorPalette: "gray", textStyle: "clean"
        ))
        #expect(!theme.hasFloatingElements)
    }

    // MARK: - Build Context

    @Test func `buildContext produces prompt with all fields`() {
        let theme = makeTheme()
        let context = theme.buildContext()
        #expect(context.contains("Visual theme: \"Space\""))
        #expect(context.contains("Overall style: cosmic"))
        #expect(context.contains("Background: deep navy"))
        #expect(context.contains("Floating decorative elements to include: twinkling stars"))
        #expect(context.contains("Color palette: deep navy"))
        #expect(context.contains("Text styling: clean"))
        #expect(context.contains("IMPORTANT:"))
    }

    @Test func `buildContext joins floating elements with commas`() {
        let theme = makeTheme()
        let context = theme.buildContext()
        #expect(context.contains("twinkling stars (varying sizes), small planets, comet trails"))
    }

    // MARK: - Build Design Context

    @Test func `buildDesignContext includes JSON schema instruction`() {
        let theme = makeTheme()
        let context = theme.buildDesignContext()
        #expect(context.contains("\"palette\""))
        #expect(context.contains("\"textColor\""))
        #expect(context.contains("\"decorations\""))
        #expect(context.contains("JSON"))
    }

    @Test func `buildDesignContext specifies normalized positions`() {
        let theme = makeTheme()
        let context = theme.buildDesignContext()
        #expect(context.contains("0-1"))
        #expect(context.contains("cqi"))
    }

    @Test func `buildDesignContext includes theme name and style`() {
        let theme = makeTheme()
        let context = theme.buildDesignContext()
        #expect(context.contains("Space"))
        #expect(context.contains("cosmic"))
    }

    // MARK: - Codable

    @Test func `theme is codable`() throws {
        let theme = makeTheme()
        let data = try JSONEncoder().encode(theme)
        let decoded = try JSONDecoder().decode(ScreenTheme.self, from: data)
        #expect(decoded == theme)
        #expect(decoded.aiHints.style == theme.aiHints.style)
    }

    @Test func `theme AI hints are codable`() throws {
        let hints = ThemeAIHints(
            style: "bold", background: "dark gradient",
            floatingElements: ["stars", "orbs"],
            colorPalette: "purple, cyan", textStyle: "uppercase glow"
        )
        let data = try JSONEncoder().encode(hints)
        let decoded = try JSONDecoder().decode(ThemeAIHints.self, from: data)
        #expect(decoded == hints)
        #expect(decoded.floatingElements == ["stars", "orbs"])
    }

    // MARK: - Affordances

    @Test func `theme affordances include apply and list commands`() {
        let theme = makeTheme(id: "neon")
        #expect(theme.affordances["detail"] == "asc app-shots themes get --id neon")
        #expect(theme.affordances["listAll"] == "asc app-shots themes list")
        #expect(theme.affordances["apply"]?.contains("--theme neon") == true)
    }
}
