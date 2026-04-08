import Foundation
import Testing
@testable import Domain

@Suite("Template Preview Page")
struct TemplatePreviewPageTests {

    @Test func `generate all templates preview page`() throws {
        let testFile = URL(fileURLWithPath: #filePath)
        var root = testFile
        for _ in 0..<5 { root = root.deletingLastPathComponent() }

        // Load iPhone frame
        let framePath = root.appendingPathComponent("examples/blitz-screenshots/plugin/ui/iphone-frame.png")
        if let frameData = try? Data(contentsOf: framePath) {
            GalleryHTMLRenderer.phoneFrameDataURL = "data:image/png;base64," + frameData.base64EncodedString()
        }

        // Load templates.json
        let jsonPath = root.appendingPathComponent("examples/blitz-screenshots/Sources/BlitzPlugin/Resources/templates.json")
        let data = try Data(contentsOf: jsonPath)
        let templates = try JSONDecoder().decode([AppShotTemplate].self, from: data)
        #expect(templates.count >= 23)

        // Build preview cards
        let cards = templates.map { tmpl -> String in
            let preview = tmpl.previewHTML
            let escaped = preview
                .replacingOccurrences(of: "&", with: "&amp;")
                .replacingOccurrences(of: "\"", with: "&quot;")
                .replacingOccurrences(of: "<", with: "&lt;")
                .replacingOccurrences(of: ">", with: "&gt;")
            return """
            <div class="card">
              <div class="preview"><iframe srcdoc="\(escaped)" style="width:100%;height:100%;border:none;pointer-events:none"></iframe></div>
              <div class="info">
                <div class="name">\(tmpl.name)</div>
                <div class="meta">\(tmpl.category.rawValue) · \(tmpl.deviceCount) device\(tmpl.deviceCount == 1 ? "" : "s")</div>
              </div>
            </div>
            """
        }.joined(separator: "\n")

        let html = """
        <!DOCTYPE html>
        <html>
        <head>
        <meta charset="utf-8">
        <title>Template Preview — All \(templates.count) Templates</title>
        <style>
        * { margin:0; padding:0; box-sizing:border-box; }
        body { background:#08090c; color:#f0f2f5; font-family:system-ui,-apple-system,sans-serif; padding:32px; }
        h1 { font-size:24px; font-weight:800; margin-bottom:24px; text-align:center; }
        .grid { display:grid; grid-template-columns:repeat(auto-fill,minmax(200px,1fr)); gap:16px; }
        .card { border:2px solid #222530; border-radius:12px; overflow:hidden; background:#12141a; }
        .preview { width:100%; aspect-ratio:9/16; position:relative; overflow:hidden; }
        .info { padding:10px 12px; }
        .name { font-size:13px; font-weight:700; }
        .meta { font-size:11px; color:#8890a0; margin-top:2px; }
        </style>
        </head>
        <body>
        <h1>All Templates (\(templates.count))</h1>
        <div class="grid">
        \(cards)
        </div>
        </body>
        </html>
        """

        let outputDir = root.appendingPathComponent(".asc/app-shots/gallery-previews")
        try FileManager.default.createDirectory(at: outputDir, withIntermediateDirectories: true)
        let file = outputDir.appendingPathComponent("all-templates.html")
        try html.write(to: file, atomically: true, encoding: .utf8)
        print("Open: open \(file.path)")
    }
}
