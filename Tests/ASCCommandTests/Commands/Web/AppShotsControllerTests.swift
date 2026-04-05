import Foundation
import Testing
import Mockable
@testable import ASCCommand
@testable import Domain

@Suite
struct AppShotsControllerTests {

    // MARK: - Templates list

    @Test func `templates list returns data with _links`() async throws {
        let mockRepo = MockTemplateRepository()
        given(mockRepo).listTemplates(size: .any).willReturn([
            makeTemplate(id: "hero", name: "Hero"),
        ])
        let templates = try await mockRepo.listTemplates(size: nil)
        let formatter = OutputFormatter(format: .json, pretty: true)
        let output = try formatter.formatAgentItems(templates, affordanceMode: .rest)
        let normalized = output.replacingOccurrences(of: "\\/", with: "/")
        #expect(normalized.contains("\"_links\""))
        #expect(normalized.contains("\"hero\""))
    }

    // MARK: - Themes list

    @Test func `themes list returns data with _links`() async throws {
        let mockRepo = MockThemeRepository()
        given(mockRepo).listThemes().willReturn([
            makeTheme(id: "neon", name: "Neon"),
        ])
        let themes = try await mockRepo.listThemes()
        let formatter = OutputFormatter(format: .json, pretty: true)
        let output = try formatter.formatAgentItems(themes, affordanceMode: .rest)
        let normalized = output.replacingOccurrences(of: "\\/", with: "/")
        #expect(normalized.contains("\"_links\""))
        #expect(normalized.contains("\"neon\""))
    }
}

// MARK: - Helpers

private func makeTemplate(id: String, name: String) -> ScreenshotTemplate {
    ScreenshotTemplate(
        id: id, name: name, category: .bold, supportedSizes: [.portrait],
        description: "Test", background: .gradient(from: "#000", to: "#111", angle: 180),
        textSlots: [TemplateTextSlot(role: .heading, preview: "Test", x: 0.5, y: 0.04, fontSize: 0.1, color: "#fff")],
        deviceSlots: [TemplateDeviceSlot(x: 0.5, y: 0.18, scale: 0.85)]
    )
}

private func makeTheme(id: String, name: String) -> ScreenTheme {
    ScreenTheme(
        id: id, name: name, icon: "⚡", description: "Test",
        accent: "#FF00FF", previewGradient: "linear-gradient(#000,#F0F)",
        aiHints: ThemeAIHints(style: "", background: "", floatingElements: [], colorPalette: "", textStyle: "")
    )
}
