import Foundation
import Testing
import Mockable
@testable import Domain

@Suite("GalleryTemplateRepository")
struct GalleryTemplateRepositoryTests {

    // ── User: "I browse gallery templates" ──

    @Test func `list returns all galleries`() async throws {
        let repo = MockGalleryTemplateRepository()
        let g1 = Gallery(appName: "App1", screenshots: ["s.png"])
        g1.template = MockRepositoryFactory.makeGalleryTemplate(id: "neon-pop")
        let g2 = Gallery(appName: "App2", screenshots: ["s.png"])
        g2.template = MockRepositoryFactory.makeGalleryTemplate(id: "blue-depth")

        given(repo).listGalleries().willReturn([g1, g2])

        let galleries = try await repo.listGalleries()
        #expect(galleries.count == 2)
        #expect(galleries[0].template?.id == "neon-pop")
        #expect(galleries[1].template?.id == "blue-depth")
    }

    // ── User: "I pick a specific gallery template" ──

    @Test func `get returns gallery by template id`() async throws {
        let repo = MockGalleryTemplateRepository()
        let g = Gallery(appName: "App", screenshots: ["s.png"])
        g.template = MockRepositoryFactory.makeGalleryTemplate(id: "neon-pop", name: "Neon Pop")

        given(repo).getGallery(templateId: .value("neon-pop")).willReturn(g)

        let gallery = try await repo.getGallery(templateId: "neon-pop")
        #expect(gallery?.template?.id == "neon-pop")
    }

    @Test func `get returns nil for unknown id`() async throws {
        let repo = MockGalleryTemplateRepository()
        given(repo).getGallery(templateId: .value("unknown")).willReturn(nil)

        let gallery = try await repo.getGallery(templateId: "unknown")
        #expect(gallery == nil)
    }
}
