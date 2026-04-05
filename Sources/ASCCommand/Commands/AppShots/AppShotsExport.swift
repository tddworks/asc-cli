import ArgumentParser
import Domain
import Foundation
import Infrastructure

struct AppShotsExport: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "export",
        abstract: "Render an HTML file to PNG via WebKit"
    )

    @Option(name: .long, help: "Path to HTML file to render")
    var html: String

    @Option(name: .long, help: "Output PNG path")
    var output: String = ".asc/app-shots/output/screen-0.png"

    @Option(name: .long, help: "Width in pixels (default: 1320)")
    var width: Int = 1320

    @Option(name: .long, help: "Height in pixels (default: 2868)")
    var height: Int = 2868

    func run() async throws {
        let renderer = ClientProvider.makeHTMLRenderer()
        print(try await execute(renderer: renderer))
    }

    func execute(renderer: any HTMLRenderer) async throws -> String {
        var htmlContent = try String(contentsOfFile: html, encoding: .utf8)

        // Ensure preview fills the full viewport for image export
        // Themed HTML from `themes apply` uses width:320px — replace with 100%
        if htmlContent.contains("width:320px") {
            htmlContent = htmlContent
                .replacingOccurrences(of: "width:320px", with: "width:100%;height:100%")
                .replacingOccurrences(of: "min-height:100vh;background:#111", with: "margin:0;overflow:hidden")
                .replacingOccurrences(of: "display:flex;justify-content:center;align-items:center;min-height:100vh;background:#111", with: "margin:0;overflow:hidden")
            // Add html,body height if missing
            if !htmlContent.contains("html,body{") {
                htmlContent = htmlContent.replacingOccurrences(of: "box-sizing:border-box}", with: "box-sizing:border-box}html,body{width:100%;height:100%}")
            }
        }

        let pngData = try await renderer.render(html: htmlContent, width: width, height: height)

        let fileURL = URL(fileURLWithPath: output)
        try FileManager.default.createDirectory(at: fileURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        try pngData.write(to: fileURL)

        let result: [String: Any] = ["exported": output, "width": width, "height": height, "bytes": pngData.count]
        let data = try JSONSerialization.data(withJSONObject: result, options: [.prettyPrinted, .sortedKeys])
        return String(data: data, encoding: .utf8) ?? "{}"
    }
}
