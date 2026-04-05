#if canImport(WebKit)
import Domain
import Foundation
import WebKit

/// Renders HTML to PNG using WKWebView snapshot on macOS.
///
/// Loads the HTML in a headless web view at the exact pixel dimensions,
/// waits for content to render, then takes a snapshot as PNG data.
public final class WebKitHTMLRenderer: HTMLRenderer, @unchecked Sendable {

    public init() {}

    public func render(html: String, width: Int, height: Int) async throws -> Data {
        try await renderOnMain(html: html, width: width, height: height)
    }

    @MainActor
    private func renderOnMain(html: String, width: Int, height: Int) async throws -> Data {
        let config = WKWebViewConfiguration()
        let webView = WKWebView(frame: NSRect(x: 0, y: 0, width: width, height: height), configuration: config)

        // Use cwd as base URL so relative image paths (e.g. .asc/app-shots/compose-1.png) resolve
        let baseURL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
        webView.loadHTMLString(html, baseURL: baseURL)

        // Wait for navigation to finish
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            let delegate = NavigationDelegate(continuation: continuation)
            webView.navigationDelegate = delegate
            // Prevent delegate from being deallocated
            objc_setAssociatedObject(webView, "navDelegate", delegate, .OBJC_ASSOCIATION_RETAIN)
        }

        // Allow extra time for CSS animations/fonts to settle
        try await Task.sleep(for: .milliseconds(500))

        let config2 = WKSnapshotConfiguration()
        config2.snapshotWidth = NSNumber(value: width)

        let image = try await webView.takeSnapshot(configuration: config2)

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
        switch self {
        case .snapshotFailed: "Failed to capture PNG snapshot from rendered HTML"
        }
    }
}
#endif
