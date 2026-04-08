/// A themed screenshot page — wraps composed HTML body in a full HTML document.
///
/// Domain value type that owns the page-wrapping logic. Used by both CLI and REST
/// after theme composition to produce the final renderable HTML.
public struct ThemedPage: Sendable, Equatable {
    public let body: String
    public let width: Int
    public let height: Int
    public let fillViewport: Bool

    public init(body: String, width: Int, height: Int, fillViewport: Bool = false) {
        self.body = body
        self.width = width
        self.height = height
        self.fillViewport = fillViewport
    }

    /// The full HTML page ready for rendering or display.
    public var html: String {
        let template = GalleryHTMLRenderer.loadTemplate("page-wrapper")
        let ctx = GalleryHTMLRenderer.pageContext(
            inner: body,
            fillViewport: fillViewport,
            width: width,
            height: height
        )
        return HTMLComposer.render(template, with: ctx)
    }
}
