import Domain
import Foundation

/// Aggregates templates from all registered `TemplateProvider`s.
///
/// The platform ships with no built-in templates. Plugins register
/// providers to supply their own templates.
///
/// Use `AggregateTemplateRepository.shared` as the global registry.
public final actor AggregateTemplateRepository: TemplateRepository {
    /// Global shared instance — plugins register providers here.
    public static let shared = AggregateTemplateRepository()

    private var providers: [any TemplateProvider] = []

    public init() {}

    public func register(provider: any TemplateProvider) {
        providers.append(provider)
    }

    public func listTemplates(size: ScreenSize?) async throws -> [AppShotTemplate] {
        var all: [AppShotTemplate] = []
        for provider in providers {
            let templates = try await provider.templates()
            all.append(contentsOf: templates)
        }

        if let size {
            return all.filter { $0.supportedSizes.contains(size) }
        }
        return all
    }

    public func getTemplate(id: String) async throws -> AppShotTemplate? {
        let all = try await listTemplates(size: nil)
        return all.first { $0.id == id }
    }
}
