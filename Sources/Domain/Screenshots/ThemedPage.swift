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
        let styles = GalleryHTMLRenderer.buildPageStyles(
            previewStyle: fillViewport
                ? "width:100%;height:100%;container-type:inline-size"
                : "width:320px;aspect-ratio:\(width)/\(height);container-type:inline-size",
            bodyStyle: fillViewport
                ? "margin:0;overflow:hidden"
                : "display:flex;justify-content:center;align-items:center;min-height:100vh;background:#111",
            htmlHeight: fillViewport ? "html,body{width:100%;height:100%}" : ""
        )
        let template = GalleryHTMLRenderer.loadPageWrapperTemplate()
        return HTMLComposer.render(template, with: [
            "styles": styles,
            "inner": body,
        ])
    }
}
