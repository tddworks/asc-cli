import Domain
import Foundation

/// Aggregates gallery templates from all registered providers.
public final actor AggregateGalleryTemplateRepository: GalleryTemplateRepository {
    public static let shared = AggregateGalleryTemplateRepository()

    private var providers: [any GalleryTemplateProvider] = []

    public init() {}

    public func register(provider: any GalleryTemplateProvider) {
        providers.append(provider)
    }

    public func listGalleries() async throws -> [Gallery] {
        var all: [Gallery] = []
        for provider in providers {
            let galleries = try await provider.galleries()
            all.append(contentsOf: galleries)
        }
        return all
    }

    public func getGallery(templateId: String) async throws -> Gallery? {
        let all = try await listGalleries()
        return all.first { $0.template?.id == templateId }
    }
}
