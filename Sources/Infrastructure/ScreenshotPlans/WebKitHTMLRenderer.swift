#if canImport(WebKit)
import AppKit
import Domain
import Foundation
import WebKit

/// Renders HTML to PNG using WKWebView snapshot on macOS.
public final class WebKitHTMLRenderer: HTMLRenderer, @unchecked Sendable {

    public init() {}

    public func render(html: String, width: Int, height: Int) async throws -> Data {
        try await renderOnMain(html: html, width: width, height: height)
    }

    @MainActor
    private func renderOnMain(html: String, width: Int, height: Int) async throws -> Data {
        let config = WKWebViewConfiguration()
        let webView = WKWebView(frame: NSRect(x: 0, y: 0, width: width, height: height), configuration: config)

        // Inline local images as data URLs so they render in loadHTMLString
        let cwd = FileManager.default.currentDirectoryPath
        let resolvedHTML = Self.inlineLocalImages(html, cwd: cwd)
        webView.loadHTMLString(resolvedHTML, baseURL: nil)

        // Wait for navigation
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            let delegate = NavigationDelegate(continuation: continuation)
            webView.navigationDelegate = delegate
            objc_setAssociatedObject(webView, "navDelegate", delegate, .OBJC_ASSOCIATION_RETAIN)
        }

        // Brief pause for CSS layout (images are already inlined as data URLs)
        try await Task.sleep(for: .milliseconds(100))

        let snapshotConfig = WKSnapshotConfiguration()
        snapshotConfig.snapshotWidth = NSNumber(value: width)

        let image = try await webView.takeSnapshot(configuration: snapshotConfig)

        guard let tiffData = image.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiffData),
              let pngData = bitmap.representation(using: .png, properties: [:]) else {
            throw HTMLRendererError.snapshotFailed
        }

        return pngData
    }

    /// Replace local image src paths with inline base64 data URLs.
    private static func inlineLocalImages(_ html: String, cwd: String) -> String {
        // Match src="<path>.png" or src="<path>.jpg" etc.
        let pattern = #"src="([^"]+\.(?:png|jpg|jpeg|gif|webp))""#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return html }
        let nsHTML = html as NSString
        var result = html
        let matches = regex.matches(in: html, range: NSRange(location: 0, length: nsHTML.length))

        // Process in reverse so replacements don't shift ranges
        for match in matches.reversed() {
            let pathRange = match.range(at: 1)
            let path = nsHTML.substring(with: pathRange)

            // Skip data URIs
            if path.hasPrefix("data:") { continue }
            // Rewrite /api/files/read URLs back to local paths
            if path.hasPrefix("http"), path.contains("/api/files/read?path=") {
                if let urlComps = URLComponents(string: path),
                   let localPath = urlComps.queryItems?.first(where: { $0.name == "path" })?.value,
                   let data = FileManager.default.contents(atPath: cwd + "/" + localPath) {
                    let ext = (localPath as NSString).pathExtension.lowercased()
                    let mime = ext == "png" ? "image/png" : ext == "jpg" || ext == "jpeg" ? "image/jpeg" : "image/\(ext)"
                    let dataURL = "data:\(mime);base64,\(data.base64EncodedString())"
                    let fullRange = match.range(at: 0)
                    result = (result as NSString).replacingCharacters(in: fullRange, with: "src=\"\(dataURL)\"")
                }
                continue
            }
            if path.hasPrefix("http") { continue }

            // Resolve relative to cwd — try direct path then .asc/app-shots/ prefix
            let candidates = [
                path.hasPrefix("/") ? path : cwd + "/" + path,
                cwd + "/.asc/app-shots/" + path,
            ]
            guard let fullPath = candidates.first(where: { FileManager.default.fileExists(atPath: $0) }),
                  let data = FileManager.default.contents(atPath: fullPath) else { continue }

            let ext = (path as NSString).pathExtension.lowercased()
            let mime = ext == "png" ? "image/png" : ext == "jpg" || ext == "jpeg" ? "image/jpeg" : "image/\(ext)"
            let dataURL = "data:\(mime);base64,\(data.base64EncodedString())"

            let fullRange = match.range(at: 0)
            result = (result as NSString).replacingCharacters(in: fullRange, with: "src=\"\(dataURL)\"")
        }
        return result
    }
}

private final class NavigationDelegate: NSObject, WKNavigationDelegate {
    private var continuation: CheckedContinuation<Void, Error>?

    init(continuation: CheckedContinuation<Void, Error>) {
        self.continuation = continuation
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        continuation?.resume()
        continuation = nil
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        continuation?.resume(throwing: error)
        continuation = nil
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        continuation?.resume(throwing: error)
        continuation = nil
    }
}

enum HTMLRendererError: Error, CustomStringConvertible {
    case snapshotFailed
    var description: String {
        switch self { case .snapshotFailed: "Failed to capture PNG snapshot from rendered HTML" }
    }
}
#endif
