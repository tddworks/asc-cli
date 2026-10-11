import CoreGraphics
import Foundation
import ImageIO
import Testing
import UniformTypeIdentifiers
@testable import ASCCommand
@testable import Domain

@Suite
struct ScreenshotImportFilesTests {

    private let directory = FileManager.default.temporaryDirectory.appendingPathComponent("import-files-\(UUID().uuidString)")

    /// Writes a solid-colour PNG of the given size.
    private func writePNG(_ name: String, width: Int, height: Int, gray: CGFloat) throws -> URL {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let context = try #require(CGContext(
            data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: 0,
            space: CGColorSpaceCreateDeviceGray(), bitmapInfo: CGImageAlphaInfo.none.rawValue
        ))
        context.setFillColor(gray: gray, alpha: 1)
        context.fill(CGRect(x: 0, y: 0, width: width, height: height))
        let image = try #require(context.makeImage())
        let url = directory.appendingPathComponent(name)
        let destination = try #require(CGImageDestinationCreateWithURL(url as CFURL, UTType.png.identifier as CFString, 1, nil))
        CGImageDestinationAddImage(destination, image, nil)
        #expect(CGImageDestinationFinalize(destination))
        return url
    }

    private func manifest(_ files: [String]) -> ScreenshotManifest {
        ScreenshotManifest(version: "1.0", exportedAt: nil, localizations: [
            "en-US": .init(displayType: .iphone67, screenshots: files.enumerated().map { .init(order: $0.offset + 1, file: $0.element) }),
        ])
    }

    @Test func `should measure each screenshot's pixel size`() throws {
        let url = try writePNG("1.png", width: 12, height: 26, gray: 0.5)

        let files = try ScreenshotImportFiles.read(manifest: manifest(["en-US/1.png"]), imageURLs: ["en-US/1.png": url])

        #expect(files.map(\.file) == ["en-US/1.png"])
        #expect(files.map(\.size) == ["12x26"])
        #expect(files.map(\.url) == [url])
    }

    @Test func `should give identical screenshots the same hash and different ones different hashes`() throws {
        let first = try writePNG("a.png", width: 4, height: 4, gray: 0.2)
        let copy = try writePNG("b.png", width: 4, height: 4, gray: 0.2)
        let other = try writePNG("c.png", width: 4, height: 4, gray: 0.9)

        let files = try ScreenshotImportFiles.read(
            manifest: manifest(["a.png", "b.png", "c.png"]), imageURLs: ["a.png": first, "b.png": copy, "c.png": other]
        )

        #expect(files[0].contentHash == files[1].contentHash)
        #expect(files[0].contentHash != files[2].contentHash)
        #expect(files[0].contentHash.count == 64)
    }

    @Test func `should refuse an export whose manifest names a file the ZIP doesn't have`() {
        #expect(throws: (any Error).self) {
            _ = try ScreenshotImportFiles.read(manifest: manifest(["en-US/missing.png"]), imageURLs: [
                "en-US/missing.png": directory.appendingPathComponent("missing.png"),
            ])
        }
    }
}
