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

    public var tagline: String?
    public var headline: String?
    public var body: String?
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
        GalleryHTMLRenderer.renderScreen(self, screenTemplate: screenTemplate, palette: palette)
    }
}

// MARK: - Codable

extension AppShot: Codable {
    private enum CodingKeys: String, CodingKey {
        case screenshot, type, tagline, headline, body, badges, trustMarks
    }

    public convenience init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let screenshot = try c.decode(String.self, forKey: .screenshot)
        let type = try c.decodeIfPresent(ScreenType.self, forKey: .type) ?? .feature
        self.init(screenshot: screenshot, type: type)
        self.tagline = try c.decodeIfPresent(String.self, forKey: .tagline)
        self.headline = try c.decodeIfPresent(String.self, forKey: .headline)
        self.body = try c.decodeIfPresent(String.self, forKey: .body)
        self.badges = try c.decodeIfPresent([String].self, forKey: .badges) ?? []
        self.trustMarks = try c.decodeIfPresent([String].self, forKey: .trustMarks)
    }

    public func encode(to encoder: any Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(screenshot, forKey: .screenshot)
        try c.encode(type, forKey: .type)
        try c.encodeIfPresent(tagline, forKey: .tagline)
        try c.encodeIfPresent(headline, forKey: .headline)
        try c.encodeIfPresent(body, forKey: .body)
        if !badges.isEmpty { try c.encode(badges, forKey: .badges) }
        try c.encodeIfPresent(trustMarks, forKey: .trustMarks)
    }
}

/// The type of screen in an App Store screenshot gallery.
public enum ScreenType: String, Sendable, Equatable, Codable {
    case hero       // first impression — branding, trust marks, big headline
    case feature    // feature showcase — headline + device frame
    case social     // social proof — ratings, testimonials, press
}
