import Domain
import Foundation

/// Aggregates themes from all registered `ThemeProvider`s.
///
/// The platform ships with no built-in themes. Plugins register
/// providers to supply their own themes with their own AI solutions.
///
/// Use `AggregateThemeRepository.shared` as the global registry.
public final actor AggregateThemeRepository: ThemeRepository {
    /// Global shared instance — plugins register providers here.
    public static let shared = AggregateThemeRepository()

    private var providers: [any ThemeProvider] = []

    public init() {}

    public func register(provider: any ThemeProvider) {
        providers.append(provider)
    }

    public func listThemes() async throws -> [ScreenTheme] {
        var all: [ScreenTheme] = []
        for provider in providers {
            let themes = try await provider.themes()
            all.append(contentsOf: themes)
        }
        return all
    }

    public func getTheme(id: String) async throws -> ScreenTheme? {
        let all = try await listThemes()
        return all.first { $0.id == id }
    }

    public func compose(themeId: String, html: String, canvasWidth: Int, canvasHeight: Int) async throws -> String {
        // Find which provider owns this theme
        for provider in providers {
            let themes = try await provider.themes()
            if let theme = themes.first(where: { $0.id == themeId }) {
                return try await provider.compose(html: html, theme: theme, canvasWidth: canvasWidth, canvasHeight: canvasHeight)
            }
        }
        throw ThemeComposeError.themeNotFound(themeId)
    }

    public func design(themeId: String) async throws -> ThemeDesign {
        for provider in providers {
            let themes = try await provider.themes()
            if let theme = themes.first(where: { $0.id == themeId }) {
                return try await provider.design(theme: theme)
            }
        }
        throw ThemeComposeError.themeNotFound(themeId)
    }
}

/// Errors from theme composition.
public enum ThemeComposeError: Error, CustomStringConvertible {
    case themeNotFound(String)

    public var description: String {
        switch self {
        case .themeNotFound(let id):
            return "Theme '\(id)' not found. Run `asc app-shots themes list` to see available themes."
        }
    }
}
