import Foundation
import Mockable
import Testing
@testable import ASCCommand
@testable import Domain

@Suite("AppShotsExport")
struct AppShotsExportTests {

    @Test func `export renders HTML file to PNG and writes output`() async throws {
        // Write a temp HTML file
        let htmlPath = NSTemporaryDirectory() + "test-export-input.html"
        let html = "<html><body><h1>Test</h1></body></html>"
        try html.write(toFile: htmlPath, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(atPath: htmlPath) }

        let outputPath = NSTemporaryDirectory() + "test-export-output.png"
        defer { try? FileManager.default.removeItem(atPath: outputPath) }

        let mockRenderer = MockHTMLRenderer()
        let fakePNG = Data([0x89, 0x50, 0x4E, 0x47])
        given(mockRenderer).render(html: .any, width: .value(1320), height: .value(2868)).willReturn(fakePNG)

        let cmd = try AppShotsExport.parse([
            "--html", htmlPath,
            "--output", outputPath,
        ])
        let output = try await cmd.execute(renderer: mockRenderer)
        #expect(output.contains("\"exported\""))
        #expect(output.contains("test-export-output.png"))

        let written = try Data(contentsOf: URL(fileURLWithPath: outputPath))
        #expect(written == fakePNG)
    }

    @Test func `export with custom dimensions passes width and height to renderer`() async throws {
        let htmlPath = NSTemporaryDirectory() + "test-export-dims.html"
        try "<html></html>".write(toFile: htmlPath, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(atPath: htmlPath) }

        let outputPath = NSTemporaryDirectory() + "test-export-dims.png"
        defer { try? FileManager.default.removeItem(atPath: outputPath) }

        let mockRenderer = MockHTMLRenderer()
        let fakePNG = Data([0x89, 0x50, 0x4E, 0x47])
        given(mockRenderer).render(html: .any, width: .value(1290), height: .value(2796)).willReturn(fakePNG)

        let cmd = try AppShotsExport.parse([
            "--html", htmlPath,
            "--output", outputPath,
            "--width", "1290",
            "--height", "2796",
        ])
        let output = try await cmd.execute(renderer: mockRenderer)
        #expect(output.contains("\"width\" : 1290"))
        #expect(output.contains("\"height\" : 2796"))
    }

    @Test func `export fails when HTML file not found`() async throws {
        let mockRenderer = MockHTMLRenderer()

        let cmd = try AppShotsExport.parse([
            "--html", "/tmp/nonexistent-file.html",
            "--output", "/tmp/out.png",
        ])
        do {
            _ = try await cmd.execute(renderer: mockRenderer)
            Issue.record("Expected error")
        } catch {
            #expect("\(error)".contains("No such file"))
        }
    }
}
