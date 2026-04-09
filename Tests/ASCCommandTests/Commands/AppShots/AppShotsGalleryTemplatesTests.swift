import Foundation
import Mockable
import Testing
@testable import ASCCommand
@testable import Domain

@Suite("AppShotsGalleryTemplates")
struct AppShotsGalleryTemplatesTests {

    // MARK: - List

    @Test func `list gallery templates returns galleries with affordances`() async throws {
        let mockRepo = MockGalleryTemplateRepository()
        let gallery = Gallery(appName: "TestApp", screenshots: ["s0.png", "s1.png"])
        gallery.template = GalleryTemplate(id: "neon-pop", name: "Neon Pop", screens: [
            .hero: ScreenLayout(headline: TextSlot(y: 0.07, size: 0.08)),
            .feature: ScreenLayout(headline: TextSlot(y: 0.05, size: 0.08)),
        ])
        gallery.palette = GalleryPalette(id: "p", name: "P", background: "#000")
        gallery.appShots[0].headline = "Hero"
        gallery.appShots[1].headline = "Feature"
        given(mockRepo).listGalleries().willReturn([gallery])

        let cmd = try AppShotsGalleryTemplatesList.parse(["--pretty"])
        let output = try await cmd.execute(repo: mockRepo)
        #expect(output.contains("\"appName\" : \"TestApp\""))
        #expect(output.contains("asc app-shots gallery-templates list"))
    }

    @Test func `list gallery templates table format`() async throws {
        let mockRepo = MockGalleryTemplateRepository()
        let gallery = Gallery(appName: "TestApp", screenshots: ["s0.png"])
        gallery.template = GalleryTemplate(id: "neon", name: "Neon", screens: [:])
        gallery.palette = GalleryPalette(id: "p", name: "P", background: "#000")
        gallery.appShots[0].headline = "Test"
        given(mockRepo).listGalleries().willReturn([gallery])

        let cmd = try AppShotsGalleryTemplatesList.parse(["--output", "table"])
        let output = try await cmd.execute(repo: mockRepo)
        #expect(output.contains("TestApp"))
    }

    // MARK: - Get

    @Test func `get gallery template returns specific gallery`() async throws {
        let mockRepo = MockGalleryTemplateRepository()
        let gallery = Gallery(appName: "BezelBlend", screenshots: ["s0.png"])
        gallery.template = GalleryTemplate(id: "neon-pop", name: "Neon Pop", screens: [:])
        gallery.palette = GalleryPalette(id: "p", name: "P", background: "#000")
        gallery.appShots[0].headline = "Premium"
        given(mockRepo).getGallery(templateId: .value("neon-pop")).willReturn(gallery)

        let cmd = try AppShotsGalleryTemplatesGet.parse(["--id", "neon-pop", "--pretty"])
        let output = try await cmd.execute(repo: mockRepo)
        #expect(output.contains("\"appName\" : \"BezelBlend\""))
    }

    @Test func `get gallery template returns error when not found`() async throws {
        let mockRepo = MockGalleryTemplateRepository()
        given(mockRepo).getGallery(templateId: .value("nope")).willReturn(nil)

        let cmd = try AppShotsGalleryTemplatesGet.parse(["--id", "nope"])
        do {
            _ = try await cmd.execute(repo: mockRepo)
            Issue.record("Expected error")
        } catch {
            #expect("\(error)".contains("not found"))
        }
    }

    @Test func `get gallery template with preview flag returns HTML`() async throws {
        let mockRepo = MockGalleryTemplateRepository()
        let gallery = Gallery(appName: "TestApp", screenshots: ["s0.png"])
        gallery.template = GalleryTemplate(id: "neon-pop", name: "Neon Pop", screens: [
            .hero: ScreenLayout(headline: TextSlot(y: 0.07, size: 0.08)),
        ])
        gallery.palette = GalleryPalette(id: "p", name: "P", background: "#000")
        gallery.appShots[0].headline = "Test"
        given(mockRepo).getGallery(templateId: .value("neon-pop")).willReturn(gallery)

        let cmd = try AppShotsGalleryTemplatesGet.parse(["--id", "neon-pop", "--preview"])
        let output = try await cmd.execute(repo: mockRepo)
        #expect(output.contains("<!DOCTYPE html>"))
    }
}
