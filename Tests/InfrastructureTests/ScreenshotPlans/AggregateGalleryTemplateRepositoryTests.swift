import Foundation
import Mockable
import Testing
@testable import Domain
@testable import Infrastructure

@Suite("AggregateGalleryTemplateRepository")
struct AggregateGalleryTemplateRepositoryTests {

    @Test func `empty repository returns no galleries`() async throws {
        let repo = AggregateGalleryTemplateRepository()
        let galleries = try await repo.listGalleries()
        #expect(galleries.isEmpty)
    }

    @Test func `registered provider galleries are returned`() async throws {
        let repo = AggregateGalleryTemplateRepository()
        let provider = MockGalleryTemplateProvider()
        given(provider).providerId.willReturn("test")
        given(provider).galleries().willReturn([
            makeGallery(templateId: "t-1", appName: "Alpha"),
            makeGallery(templateId: "t-2", appName: "Beta"),
        ])
        await repo.register(provider: provider)

        let galleries = try await repo.listGalleries()
        #expect(galleries.count == 2)
        #expect(galleries[0].appName == "Alpha")
        #expect(galleries[1].appName == "Beta")
    }

    @Test func `multiple providers are aggregated in registration order`() async throws {
        let repo = AggregateGalleryTemplateRepository()
        let providerA = MockGalleryTemplateProvider()
        given(providerA).providerId.willReturn("a")
        given(providerA).galleries().willReturn([makeGallery(templateId: "a-1", appName: "A1")])

        let providerB = MockGalleryTemplateProvider()
        given(providerB).providerId.willReturn("b")
        given(providerB).galleries().willReturn([
            makeGallery(templateId: "b-1", appName: "B1"),
            makeGallery(templateId: "b-2", appName: "B2"),
        ])

        await repo.register(provider: providerA)
        await repo.register(provider: providerB)

        let galleries = try await repo.listGalleries()
        #expect(galleries.count == 3)
        #expect(galleries.map(\.appName) == ["A1", "B1", "B2"])
    }

    @Test func `getGallery returns the matching template`() async throws {
        let repo = AggregateGalleryTemplateRepository()
        let provider = MockGalleryTemplateProvider()
        given(provider).providerId.willReturn("test")
        given(provider).galleries().willReturn([
            makeGallery(templateId: "t-1", appName: "Alpha"),
            makeGallery(templateId: "t-2", appName: "Beta"),
        ])
        await repo.register(provider: provider)

        let found = try await repo.getGallery(templateId: "t-2")
        #expect(found?.appName == "Beta")
        #expect(found?.template?.id == "t-2")
    }

    @Test func `getGallery returns nil when templateId is unknown`() async throws {
        let repo = AggregateGalleryTemplateRepository()
        let provider = MockGalleryTemplateProvider()
        given(provider).providerId.willReturn("test")
        given(provider).galleries().willReturn([makeGallery(templateId: "t-1", appName: "Alpha")])
        await repo.register(provider: provider)

        let found = try await repo.getGallery(templateId: "missing")
        #expect(found == nil)
    }

    @Test func `provider errors propagate to caller`() async throws {
        let repo = AggregateGalleryTemplateRepository()
        let provider = MockGalleryTemplateProvider()
        given(provider).providerId.willReturn("broken")
        given(provider).galleries().willThrow(StubError.boom)
        await repo.register(provider: provider)

        await #expect(throws: StubError.self) {
            _ = try await repo.listGalleries()
        }
    }
}

// MARK: - Helpers

private func makeGallery(templateId: String, appName: String) -> Gallery {
    let gallery = Gallery(appName: appName, screenshots: ["screen-0.png"])
    gallery.template = GalleryTemplate(id: templateId, name: "Template \(templateId)")
    return gallery
}

private enum StubError: Error { case boom }
