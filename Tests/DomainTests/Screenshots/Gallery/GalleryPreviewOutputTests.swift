import Foundation
import Testing
@testable import Domain

@Suite("Gallery Preview Output")
struct GalleryPreviewOutputTests {

    @Test func `gallery previewHTML renders all panels with correct content`() throws {
        // Load real iPhone frame PNG
        let testFile = URL(fileURLWithPath: #filePath)
        var projectRoot = testFile
        for _ in 0..<5 { projectRoot = projectRoot.deletingLastPathComponent() }
        let framePath = projectRoot.appendingPathComponent("examples/blitz-screenshots/plugin/ui/iphone-frame.png")
        if let frameData = try? Data(contentsOf: framePath) {
            GalleryHTMLRenderer.phoneFrameDataURL = "data:image/png;base64," + frameData.base64EncodedString()
        }

        // Load real gallery-templates.json — it's [Gallery] now
        let jsonPath = projectRoot.appendingPathComponent("examples/blitz-screenshots/Sources/BlitzPlugin/Resources/gallery-templates.json")
        let data = try Data(contentsOf: jsonPath)
        let galleries = try JSONDecoder().decode([Gallery].self, from: data)
        #expect(galleries.count == 8)

        // Each gallery has unique content
        let neonPop = galleries[0]
        #expect(neonPop.template?.id == "neon-pop")
        #expect(neonPop.appShots[0].headline == "PREMIUM\nDEVICE\nMOCKUPS.")

        let blueDepth = galleries[1]
        #expect(blueDepth.template?.id == "blue-depth")
        #expect(blueDepth.appShots[0].headline == "BezelBlend")

        // Generate preview HTML and write to disk
        let outputDir = projectRoot.appendingPathComponent(".asc/app-shots/gallery-previews")
        try FileManager.default.createDirectory(at: outputDir, withIntermediateDirectories: true)

        for gallery in galleries {
            let html = gallery.previewHTML
            #expect(!html.isEmpty, "Preview for \(gallery.template?.id ?? "?") should not be empty")

            let file = outputDir.appendingPathComponent("\(gallery.template?.id ?? "unknown").html")
            try html.write(to: file, atomically: true, encoding: .utf8)
        }

        print("Open: open \(outputDir.path)/neon-pop.html")
    }
}
