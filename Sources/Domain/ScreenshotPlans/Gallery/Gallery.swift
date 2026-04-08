import Foundation

/// A coordinated set of App Store screenshots for an app.
///
/// Created from screenshot files. First becomes hero, rest are features.
/// Apply a template (where things go) and palette (colors) to render.
///
/// ```
/// let gallery = Gallery(appName: "BezelBlend",
///                        screenshots: ["screen-0.png", "screen-1.png"])
/// gallery.appShots[0].headline = "PREMIUM DEVICE MOCKUPS."
/// gallery.template = featureWalkthrough
/// gallery.palette = greenMint
/// gallery.isReady  // → true when all shots configured + template + palette
/// ```
public final class Gallery: @unchecked Sendable, Identifiable {
    public let id: String
    public let appName: String

    public private(set) var appShots: [AppShot]
    public var template: GalleryTemplate?
    public var palette: GalleryPalette?

    /// Create a gallery from screenshot files.
    /// First screenshot becomes `.hero`, rest become `.feature`.
    public init(
        id: String = UUID().uuidString,
        appName: String,
        screenshots: [String]
    ) {
        self.id = id
        self.appName = appName
        self.appShots = screenshots.enumerated().map { index, file in
            AppShot(
                screenshot: file,
                type: index == 0 ? .hero : .feature
            )
        }
    }

    // MARK: - Apply Screenshots

    /// Create a new Gallery from a sample gallery template, replacing screenshots with user's files.
    /// Copies template, palette, and content (headline, badges, etc.) from the sample.
    public func applyScreenshots(_ screenshots: [String]) -> Gallery {
        let gallery = Gallery(appName: appName, screenshots: screenshots)
        gallery.template = template
        gallery.palette = palette
        for (i, shot) in gallery.appShots.enumerated() {
            if i < appShots.count {
                let sample = appShots[i]
                shot.headline = sample.headline
                shot.tagline = sample.tagline
                shot.body = sample.body
                shot.badges = sample.badges
                shot.trustMarks = sample.trustMarks
            }
        }
        return gallery
    }

    // MARK: - Screenshot Distribution

    /// Distribute screenshots across screens based on device count per screen.
    /// Multi-device templates consume multiple screenshots per screen.
    ///
    /// - Returns: Array of screenshot groups. Each group fills one screen's devices.
    public static func distributeScreenshots(
        _ screenshots: [String],
        screenLayout: ScreenLayout
    ) -> [[String]] {
        let devicesPerScreen = max(1, screenLayout.deviceCount)
        var result: [[String]] = []
        var i = 0
        while i < screenshots.count {
            let end = min(i + devicesPerScreen, screenshots.count)
            result.append(Array(screenshots[i..<end]))
            i = end
        }
        return result
    }

    // MARK: - Queries

    public var shotCount: Int { appShots.count }

    public var heroShot: AppShot? { appShots.first }

    public var unconfiguredShots: [AppShot] {
        appShots.filter { !$0.isConfigured }
    }

    public var isReady: Bool {
        template != nil && palette != nil && appShots.allSatisfy(\.isConfigured)
    }

    // MARK: - Render

    /// Render all configured shots as HTML.
    /// Each shot uses the screen template matching its type from the gallery template.
    public func renderAll() -> [String] {
        guard let template, let palette else { return [] }
        return appShots.compactMap { shot in
            guard shot.isConfigured,
                  let screenLayout = template.screens[shot.type] else { return nil }
            return shot.compose(screenLayout: screenLayout, palette: palette)
        }
    }

    /// Render a single shot at index.
    /// Optionally override the screen template (for per-shot customization in the UI).
    public func renderShot(
        at index: Int,
        with overrideTemplate: ScreenLayout? = nil
    ) -> String? {
        guard let template, let palette,
              appShots.indices.contains(index),
              appShots[index].isConfigured else { return nil }
        let shot = appShots[index]
        let screenLayout = overrideTemplate ?? template.screens[shot.type]
        guard let screenLayout else { return nil }
        return shot.compose(screenLayout: screenLayout, palette: palette)
    }

    /// Self-contained HTML preview showing all panels as a horizontal gallery strip.
    public var previewHTML: String {
        GalleryHTMLRenderer.renderPreviewPage(self)
    }

    public var readiness: GalleryReadiness {
        GalleryReadiness(
            hasPalette: palette != nil,
            hasTemplate: template != nil,
            configuredCount: appShots.filter(\.isConfigured).count,
            totalCount: appShots.count
        )
    }
}

// MARK: - Codable

extension Gallery: Codable {
    private enum CodingKeys: String, CodingKey {
        case appName, appShots, template, palette, previewHTML
    }

    public convenience init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let appName = try c.decode(String.self, forKey: .appName)
        // Decode appShots directly — they carry their own screenshot/type/content
        let shots = try c.decode([AppShot].self, forKey: .appShots)
        self.init(appName: appName, screenshots: [])
        self.appShots = shots
        self.template = try c.decodeIfPresent(GalleryTemplate.self, forKey: .template)
        self.palette = try c.decodeIfPresent(GalleryPalette.self, forKey: .palette)
    }

    public func encode(to encoder: any Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(appName, forKey: .appName)
        try c.encode(appShots, forKey: .appShots)
        try c.encodeIfPresent(template, forKey: .template)
        try c.encodeIfPresent(palette, forKey: .palette)
        try c.encode(previewHTML, forKey: .previewHTML)
    }
}

/// Progress check for a gallery.
public struct GalleryReadiness: Sendable, Equatable {
    public let hasPalette: Bool
    public let hasTemplate: Bool
    public let configuredCount: Int
    public let totalCount: Int

    public var isReady: Bool { hasPalette && hasTemplate && configuredCount == totalCount }
    public var progress: String { "\(configuredCount)/\(totalCount) app shots configured" }
}
