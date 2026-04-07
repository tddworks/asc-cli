import Foundation
import Testing
@testable import Domain

@Suite("Gallery Preview Output")
struct GalleryPreviewOutputTests {

    @Test func `gallery renders all panels as preview HTML`() throws {
        // Load real iPhone frame PNG for bezel rendering
        let testFile = URL(fileURLWithPath: #filePath)
        var projectRoot = testFile
        for _ in 0..<5 { projectRoot = projectRoot.deletingLastPathComponent() }
        let framePath = projectRoot.appendingPathComponent("examples/blitz-screenshots/plugin/ui/iphone-frame.png")
        if let frameData = try? Data(contentsOf: framePath) {
            GalleryHTMLRenderer.phoneFrameDataURL = "data:image/png;base64," + frameData.base64EncodedString()
        }

        // Step 1: Create gallery from screenshots (mock)
        let gallery = Gallery(
            appName: "BezelBlend",
            screenshots: ["screen-0.png", "screen-1.png", "screen-2.png", "screen-3.png"]
        )

        // Step 2: Configure panels with real content
        gallery.appShots[0].headline = "PREMIUM\nDEVICE\nMOCKUPS."
        gallery.appShots[0].badges = ["iPhone 17", "Ultra 3"]
        gallery.appShots[0].trustMarks = ["4.9 STARS", "PRO QUALITY", "50K+ DESIGNERS"]

        gallery.appShots[1].headline = "CUSTOMIZE\nEVERY DETAIL"
        gallery.appShots[1].badges = ["Mesh", "Gradient"]

        gallery.appShots[2].headline = "TEMPLATES\nMADE EASY"
        gallery.appShots[2].badges = ["Presets", "App Store"]

        gallery.appShots[3].headline = "PERFECT\nDIMENSIONS"
        gallery.appShots[3].badges = ["16:9", "4:5"]

        // Step 3: Apply template + palette
        gallery.template = GalleryTemplate(
            id: "neon-pop",
            name: "Neon Pop",
            description: "Vibrant green gradient",
            background: "linear-gradient(165deg, #a8ff78, #78ffd6, #4ade80)",
            screens: [
                .hero: ScreenTemplate(
                    headline: TextSlot(y: 0.07, size: 0.08, weight: 900, align: "left")
                ),
                .feature: ScreenTemplate(
                    headline: TextSlot(y: 0.05, size: 0.08, weight: 900, align: "left"),
                    device: DeviceSlot(y: 0.36, width: 0.68)
                ),
            ]
        )
        gallery.palette = GalleryPalette(
            id: "green",
            name: "Green Mint",
            background: "linear-gradient(165deg, #a8ff78, #78ffd6, #4ade80)"
        )

        // Step 4: Render all
        let panels = gallery.renderAll()
        #expect(panels.count == 4)

        // Each panel has the right content
        #expect(panels[0].contains("PREMIUM"))
        #expect(panels[1].contains("CUSTOMIZE"))
        #expect(panels[2].contains("TEMPLATES"))
        #expect(panels[3].contains("PERFECT"))

        // Feature panels have device frames (wireframe with 9:41 status bar)
        #expect(panels[1].contains("9:41"))
        #expect(panels[2].contains("9:41"))

        // All panels have the green background
        for panel in panels {
            #expect(panel.contains("#a8ff78"))
        }

        // Write a full gallery HTML page to disk for visual verification
        let outputDir = projectRoot.appendingPathComponent(".asc/app-shots/gallery-previews")
        try FileManager.default.createDirectory(at: outputDir, withIntermediateDirectories: true)

        let fullHTML = buildGalleryPage(panels: panels)
        let file = outputDir.appendingPathComponent("neon-pop-gallery.html")
        try fullHTML.write(to: file, atomically: true, encoding: .utf8)
        print("Open: open \(file.path)")
    }

    /// Wrap rendered panels in a gallery page — horizontal scrolling strip
    private func buildGalleryPage(panels: [String]) -> String {
        let panelDivs = panels.map { panel in
            """
            <div style="width:320px;aspect-ratio:1320/2868;border-radius:14px;overflow:hidden;flex-shrink:0;box-shadow:0 2px 8px rgba(0,0,0,0.08),0 8px 24px rgba(0,0,0,0.06)">
            \(panel)
            </div>
            """
        }.joined(separator: "\n")

        return """
        <!DOCTYPE html>
        <html>
        <head>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width,initial-scale=1">
        <title>Gallery Preview</title>
        <style>
        *{margin:0;padding:0;box-sizing:border-box}
        body{background:#dfe2e8;min-height:100vh;display:flex;align-items:center;justify-content:center;padding:24px;font-family:system-ui,-apple-system,sans-serif}
        .gallery{display:flex;gap:14px;overflow-x:auto;padding:24px}
        .dw{position:absolute;z-index:2}
        .df{width:100%;position:relative;aspect-ratio:1470/3000;filter:drop-shadow(0 4px 16px rgba(0,0,0,0.2))}
        .ds{position:absolute;inset:2.6% 2.2%;border-radius:8%/4%;overflow:hidden;background:#000}
        .ds img{width:100%;height:100%;object-fit:cover;display:block}
        .dfi{position:absolute;inset:0;width:100%;height:100%;pointer-events:none;z-index:3}
        </style>
        </head>
        <body>
        <div class="gallery">
        \(panelDivs)
        </div>
        </body>
        </html>
        """
    }
}
