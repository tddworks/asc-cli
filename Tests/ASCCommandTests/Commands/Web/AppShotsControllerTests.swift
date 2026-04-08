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

private func makeTemplate(id: String, name: String) -> AppShotTemplate {
    AppShotTemplate(
        id: id, name: name, category: .bold, supportedSizes: [.portrait], description: "Test",
        screenLayout: ScreenLayout(headline: TextSlot(y: 0.04, size: 0.1, weight: 700, align: "center"), device: DeviceSlot(x: 0.5, y: 0.18, width: 0.85)),
        palette: GalleryPalette(id: id, name: name, background: "linear-gradient(180deg,#000,#111)")
    )
}

private func makeTheme(id: String, name: String) -> ScreenTheme {
    ScreenTheme(
        id: id, name: name, icon: "⚡", description: "Test",
        accent: "#FF00FF", previewGradient: "linear-gradient(#000,#F0F)",
        aiHints: ThemeAIHints(style: "", background: "", floatingElements: [], colorPalette: "", textStyle: "")
    )
}
