#if canImport(WebKit)
import AppKit
import Foundation
import WebKit

/// Renders HTML to PNG using WKWebView snapshot on macOS. Only the WebKit
/// calls live here; which images to inline is `LocalImages`'.
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
        let resolvedHTML = LocalImages(
            workingDirectory: FileManager.default.currentDirectoryPath,
            contents: { FileManager.default.contents(atPath: $0) }
        ).inline(into: html)
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
