import Foundation
import Mockable
import Testing
@testable import ASCCommand
@testable import Domain

@Suite("AppShotsTemplates")
struct AppShotsTemplatesTests {

    // MARK: - List

    @Test func `list templates shows all templates with affordances`() async throws {
        let mockRepo = MockTemplateRepository()
        given(mockRepo).listTemplates(size: .value(nil)).willReturn([
            makeTemplate(id: "top-hero", name: "Top Hero"),
            makeTemplate(id: "minimal-light", name: "Minimal Light"),
        ])

        let cmd = try AppShotsTemplatesList.parse(["--pretty"])
        let output = try await cmd.execute(repo: mockRepo)
        #expect(output.contains("\"id\" : \"top-hero\""))
        #expect(output.contains("\"name\" : \"Top Hero\""))
        #expect(output.contains("\"id\" : \"minimal-light\""))
        #expect(output.contains("asc app-shots templates list"))
    }

    @Test func `list templates filters by size`() async throws {
        let mockRepo = MockTemplateRepository()
        given(mockRepo).listTemplates(size: .value(.landscape)).willReturn([
            makeTemplate(id: "triple-fan", name: "Triple Fan"),
        ])

        let cmd = try AppShotsTemplatesList.parse(["--size", "landscape", "--pretty"])
        let output = try await cmd.execute(repo: mockRepo)
        #expect(output.contains("\"id\" : \"triple-fan\""))
    }

    // MARK: - Get

    @Test func `get template by id returns template detail`() async throws {
        let mockRepo = MockTemplateRepository()
        given(mockRepo).getTemplate(id: .value("top-hero")).willReturn(
            makeTemplate(id: "top-hero", name: "Top Hero")
        )

        let cmd = try AppShotsTemplatesGet.parse(["--id", "top-hero", "--pretty"])
        let output = try await cmd.execute(repo: mockRepo)
        #expect(output.contains("\"id\" : \"top-hero\""))
        #expect(output.contains("\"name\" : \"Top Hero\""))
        #expect(output.contains("asc app-shots templates apply --id top-hero"))
    }

    @Test func `get template returns error when not found`() async throws {
        let mockRepo = MockTemplateRepository()
        given(mockRepo).getTemplate(id: .value("nope")).willReturn(nil)

        let cmd = try AppShotsTemplatesGet.parse(["--id", "nope"])
        do {
            _ = try await cmd.execute(repo: mockRepo)
            Issue.record("Expected error")
        } catch {
            #expect("\(error)".contains("not found"))
        }
    }
    // MARK: - Apply

    @Test func `apply template returns screen design with preview`() async throws {
        let mockRepo = MockTemplateRepository()
        given(mockRepo).getTemplate(id: .value("top-hero")).willReturn(
            makeTemplate(id: "top-hero", name: "Top Hero")
        )

        let cmd = try AppShotsTemplatesApply.parse([
            "--id", "top-hero",
            "--screenshot", "screen-1.png",
            "--headline", "Ship Faster",
            "--app-name", "MyApp",
            "--pretty"
        ])
        let output = try await cmd.execute(repo: mockRepo)
        #expect(output.contains("Ship Faster"))
        #expect(output.contains("screen-1.png"))
        #expect(output.contains("asc app-shots templates"))
    }

    @Test func `apply with preview image renders HTML to PNG and writes file`() async throws {
        let mockRepo = MockTemplateRepository()
        given(mockRepo).getTemplate(id: .value("top-hero")).willReturn(
            makeTemplate(id: "top-hero", name: "Top Hero")
        )

        let mockRenderer = MockHTMLRenderer()
        let fakePNG = Data([0x89, 0x50, 0x4E, 0x47])
        given(mockRenderer).render(html: .any, width: .any, height: .any).willReturn(fakePNG)

        let outputPath = NSTemporaryDirectory() + "test-template-export.png"

        let cmd = try AppShotsTemplatesApply.parse([
            "--id", "top-hero",
            "--screenshot", "screen-1.png",
            "--headline", "Ship Faster",
            "--preview", "image",
            "--image-output", outputPath,
        ])
        let output = try await cmd.execute(repo: mockRepo, renderer: mockRenderer)
        #expect(output.contains("\"exported\""))
        #expect(output.contains("test-template-export.png"))

        let written = try Data(contentsOf: URL(fileURLWithPath: outputPath))
        #expect(written == fakePNG)
        try? FileManager.default.removeItem(atPath: outputPath)
    }

    @Test func `apply with preview html outputs HTML page`() async throws {
        let mockRepo = MockTemplateRepository()
        given(mockRepo).getTemplate(id: .value("top-hero")).willReturn(
            makeTemplate(id: "top-hero", name: "Top Hero")
        )

        let cmd = try AppShotsTemplatesApply.parse([
            "--id", "top-hero",
            "--screenshot", "screen-1.png",
            "--headline", "Ship Faster",
            "--preview", "html",
        ])
        let output = try await cmd.execute(repo: mockRepo)
        #expect(output.contains("<!DOCTYPE html>"))
        #expect(output.contains("Ship Faster"))
    }

    @Test func `apply returns error when template not found`() async throws {
        let mockRepo = MockTemplateRepository()
        given(mockRepo).getTemplate(id: .value("nope")).willReturn(nil)

        let cmd = try AppShotsTemplatesApply.parse([
            "--id", "nope",
            "--screenshot", "screen.png",
            "--headline", "Test"
        ])
        do {
            _ = try await cmd.execute(repo: mockRepo)
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
        screenTemplate: ScreenTemplate(
            headline: TextSlot(y: 0.04, size: 0.1, weight: 700, align: "center"),
            device: DeviceSlot(x: 0.5, y: 0.18, width: 0.85)
        ),
        palette: GalleryPalette(id: id, name: name, background: "linear-gradient(180deg,#000,#111)")
    )
}
