import Foundation
import Mockable
import Testing
@testable import ASCCommand
@testable import Domain

@Suite("AppShotsThemes")
struct AppShotsThemesTests {

    // MARK: - Helpers

    private func makeTheme(id: String = "space", name: String = "Space") -> ScreenTheme {
        ScreenTheme(
            id: id, name: name, icon: "🚀",
            description: "Cosmic backgrounds, twinkling stars",
            accent: "#3b82f6",
            previewGradient: "linear-gradient(135deg, #0f172a, #7c3aed)",
            aiHints: ThemeAIHints(
                style: "cosmic and vast",
                background: "deep navy-to-purple gradient",
                floatingElements: ["twinkling stars", "comet trails"],
                colorPalette: "deep navy, indigo, bright blue",
                textStyle: "clean, modern, light on dark"
            )
        )
    }

    // MARK: - List

    @Test func `list themes returns all themes with affordances`() async throws {
        let mockRepo = MockThemeRepository()
        given(mockRepo).listThemes().willReturn([
            makeTheme(id: "space", name: "Space"),
            makeTheme(id: "neon", name: "Neon"),
        ])

        let cmd = try AppShotsThemesList.parse(["--pretty"])
        let output = try await cmd.execute(repo: mockRepo)
        #expect(output.contains("\"id\" : \"space\""))
        #expect(output.contains("\"id\" : \"neon\""))
        #expect(output.contains("asc app-shots themes list"))
        #expect(output.contains("asc app-shots themes get --id"))
    }

    @Test func `list themes table format shows name and icon`() async throws {
        let mockRepo = MockThemeRepository()
        given(mockRepo).listThemes().willReturn([
            makeTheme(id: "space", name: "Space"),
        ])

        let cmd = try AppShotsThemesList.parse(["--output", "table"])
        let output = try await cmd.execute(repo: mockRepo)
        #expect(output.contains("Space"))
    }

    // MARK: - Get

    @Test func `get theme returns specific theme with AI hints`() async throws {
        let mockRepo = MockThemeRepository()
        given(mockRepo).getTheme(id: .value("space")).willReturn(makeTheme())

        let cmd = try AppShotsThemesGet.parse(["--id", "space", "--pretty"])
        let output = try await cmd.execute(repo: mockRepo)
        #expect(output.contains("\"id\" : \"space\""))
        #expect(output.contains("\"name\" : \"Space\""))
        #expect(output.contains("cosmic"))
        #expect(output.contains("asc app-shots themes get --id space"))
    }

    @Test func `get theme returns error when not found`() async throws {
        let mockRepo = MockThemeRepository()
        given(mockRepo).getTheme(id: .value("nonexistent")).willReturn(nil)

        let cmd = try AppShotsThemesGet.parse(["--id", "nonexistent"])
        do {
            _ = try await cmd.execute(repo: mockRepo)
            Issue.record("Expected error")
        } catch {
            #expect("\(error)".contains("not found"))
        }
    }

    @Test func `get theme with context flag outputs buildContext string`() async throws {
        let mockRepo = MockThemeRepository()
        given(mockRepo).getTheme(id: .value("space")).willReturn(makeTheme())

        let cmd = try AppShotsThemesGet.parse(["--id", "space", "--context"])
        let output = try await cmd.execute(repo: mockRepo)
        #expect(output.contains("Visual theme: \"Space\""))
        #expect(output.contains("Overall style:"))
        #expect(output.contains("Floating decorative elements to include:"))
    }

    // MARK: - Apply

    @Test func `apply renders template then composes with theme`() async throws {
        let mockThemeRepo = MockThemeRepository()
        given(mockThemeRepo).compose(themeId: .value("space"), html: .any, canvasWidth: .any, canvasHeight: .any)
            .willReturn("<div>themed output</div>")

        let mockTemplateRepo = MockTemplateRepository()
        given(mockTemplateRepo).getTemplate(id: .value("top-hero")).willReturn(
            makeTemplate(id: "top-hero", name: "Top Hero")
        )

        let cmd = try AppShotsThemesApply.parse([
            "--theme", "space",
            "--template", "top-hero",
            "--screenshot", "screen.png",
            "--headline", "Ship Faster",
        ])
        let output = try await cmd.execute(themeRepo: mockThemeRepo, templateRepo: mockTemplateRepo)
        #expect(output.contains("<div>themed output</div>"))
    }

    @Test func `apply fails when template not found`() async throws {
        let mockThemeRepo = MockThemeRepository()
        let mockTemplateRepo = MockTemplateRepository()
        given(mockTemplateRepo).getTemplate(id: .value("nope")).willReturn(nil)

        let cmd = try AppShotsThemesApply.parse([
            "--theme", "space",
            "--template", "nope",
            "--screenshot", "screen.png",
            "--headline", "Test",
        ])
        do {
            _ = try await cmd.execute(themeRepo: mockThemeRepo, templateRepo: mockTemplateRepo)
            Issue.record("Expected error")
        } catch {
            #expect("\(error)".contains("not found"))
        }
    }
}

// MARK: - Helpers

private func makeTemplate(id: String, name: String) -> ScreenshotTemplate {
    ScreenshotTemplate(
        id: id,
        name: name,
        category: .bold,
        supportedSizes: [.portrait],
        description: "Test",
        background: .gradient(from: "#000", to: "#111", angle: 180),
        textSlots: [TemplateTextSlot(role: .heading, preview: "Test", x: 0.5, y: 0.04, fontSize: 0.1, color: "#fff")],
        deviceSlots: [TemplateDeviceSlot(x: 0.5, y: 0.18, scale: 0.85)]
    )
}
