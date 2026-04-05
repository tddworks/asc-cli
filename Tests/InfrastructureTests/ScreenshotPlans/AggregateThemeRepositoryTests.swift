import Foundation
import Mockable
import Testing
@testable import Domain
@testable import Infrastructure

@Suite("AggregateThemeRepository")
struct AggregateThemeRepositoryTests {

    // MARK: - Helpers

    private func makeTheme(id: String, name: String) -> ScreenTheme {
        ScreenTheme(
            id: id, name: name, icon: "🎨",
            description: "Test theme",
            accent: "#000", previewGradient: "linear-gradient(#000,#111)",
            aiHints: ThemeAIHints(
                style: "test", background: "dark",
                floatingElements: ["stars"],
                colorPalette: "black, white",
                textStyle: "bold"
            )
        )
    }

    @Test func `listThemes returns empty when no providers registered`() async throws {
        let repo = AggregateThemeRepository()
        let themes = try await repo.listThemes()
        #expect(themes.isEmpty)
    }

    @Test func `listThemes returns themes from registered provider`() async throws {
        let repo = AggregateThemeRepository()
        let mockProvider = MockThemeProvider()
        given(mockProvider).providerId.willReturn("test")
        given(mockProvider).themes().willReturn([
            makeTheme(id: "neon", name: "Neon"),
            makeTheme(id: "space", name: "Space"),
        ])

        await repo.register(provider: mockProvider)
        let themes = try await repo.listThemes()
        #expect(themes.count == 2)
        #expect(themes[0].id == "neon")
        #expect(themes[1].id == "space")
    }

    @Test func `listThemes aggregates from multiple providers`() async throws {
        let repo = AggregateThemeRepository()

        let provider1 = MockThemeProvider()
        given(provider1).providerId.willReturn("blitz")
        given(provider1).themes().willReturn([makeTheme(id: "neon", name: "Neon")])

        let provider2 = MockThemeProvider()
        given(provider2).providerId.willReturn("custom")
        given(provider2).themes().willReturn([makeTheme(id: "ocean", name: "Ocean")])

        await repo.register(provider: provider1)
        await repo.register(provider: provider2)
        let themes = try await repo.listThemes()
        #expect(themes.count == 2)
    }

    @Test func `getTheme finds theme by id`() async throws {
        let repo = AggregateThemeRepository()
        let mockProvider = MockThemeProvider()
        given(mockProvider).providerId.willReturn("test")
        given(mockProvider).themes().willReturn([
            makeTheme(id: "neon", name: "Neon"),
            makeTheme(id: "space", name: "Space"),
        ])

        await repo.register(provider: mockProvider)
        let theme = try await repo.getTheme(id: "space")
        #expect(theme?.name == "Space")
    }

    @Test func `getTheme returns nil for unknown id`() async throws {
        let repo = AggregateThemeRepository()
        let mockProvider = MockThemeProvider()
        given(mockProvider).providerId.willReturn("test")
        given(mockProvider).themes().willReturn([makeTheme(id: "neon", name: "Neon")])

        await repo.register(provider: mockProvider)
        let theme = try await repo.getTheme(id: "nonexistent")
        #expect(theme == nil)
    }

    // MARK: - Compose

    @Test func `compose delegates to the provider that owns the theme`() async throws {
        let repo = AggregateThemeRepository()
        let mockProvider = MockThemeProvider()
        let neonTheme = makeTheme(id: "neon", name: "Neon")
        given(mockProvider).providerId.willReturn("blitz")
        given(mockProvider).themes().willReturn([neonTheme])
        given(mockProvider).compose(html: .any, theme: .any, canvasWidth: .any, canvasHeight: .any)
            .willReturn("<div>themed</div>")

        await repo.register(provider: mockProvider)
        let result = try await repo.compose(themeId: "neon", html: "<div>original</div>", canvasWidth: 1320, canvasHeight: 2868)
        #expect(result == "<div>themed</div>")
    }

    @Test func `compose throws when theme not found`() async throws {
        let repo = AggregateThemeRepository()
        do {
            _ = try await repo.compose(themeId: "nonexistent", html: "<div/>", canvasWidth: 1320, canvasHeight: 2868)
            Issue.record("Expected error")
        } catch {
            #expect("\(error)".contains("not found"))
        }
    }
}
