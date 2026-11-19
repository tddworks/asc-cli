import Foundation
import Mockable

/// Renders an HTML string to a PNG image at the specified pixel dimensions.
///
/// Used by `app-shots themes apply --format image` and `templates apply --format image`
/// to convert composed HTML screenshots into App Store-ready PNG files.
///
/// Infrastructure provides `WebKitHTMLRenderer` using WKWebView snapshot on macOS.
@Mockable
public protocol HTMLRenderer: Sendable {
    /// Render HTML content to PNG image data at the given pixel dimensions.
    ///
    /// - Parameters:
    ///   - html: Self-contained HTML string (full document or fragment)
    ///   - width: Target width in pixels
    ///   - height: Target height in pixels
    /// - Returns: PNG image data
    func render(html: String, width: Int, height: Int) async throws -> Data
}
