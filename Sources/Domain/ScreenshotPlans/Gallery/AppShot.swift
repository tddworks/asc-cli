import Foundation

/// A single designed App Store screenshot.
///
/// Named after the CLI command `asc app-shots`.
/// Can be used standalone or as part of a `Gallery`.
///
/// ```
/// let shot = AppShot(screenshot: "screen-0.png", type: .hero)
/// shot.headline = "Make your map yours"
/// shot.badges = ["iPhone 17", "Ultra 3"]
/// shot.isConfigured  // → true
/// ```
public final class AppShot: @unchecked Sendable, Identifiable {
    public let id: String
    public let screenshot: String
    public private(set) var type: ScreenType

    public var headline: String?
    public var badges: [String]
    public var trustMarks: [String]?

    public init(
        id: String = UUID().uuidString,
        screenshot: String,
        type: ScreenType = .feature
    ) {
        self.id = id
        self.screenshot = screenshot
        self.type = type
        self.badges = []
    }

    /// Whether this app shot has enough content to render.
    public var isConfigured: Bool {
        guard let headline else { return false }
        return !headline.isEmpty
    }

    /// Compose this shot into HTML using a screen template and palette.
    /// Caller decides which template — enables per-shot override.
    public func compose(screenTemplate: ScreenTemplate, palette: GalleryPalette) -> String {
        GalleryHTMLRenderer.renderPanel(self, screenTemplate: screenTemplate, palette: palette)
    }
}

/// The type of screen in an App Store screenshot gallery.
public enum ScreenType: String, Sendable, Equatable, Codable {
    case hero       // first impression — branding, trust marks, big headline
    case feature    // feature showcase — headline + device frame
    case social     // social proof — ratings, testimonials, press
}
