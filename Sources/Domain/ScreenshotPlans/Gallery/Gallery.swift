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

    // MARK: - Queries

    public var shotCount: Int { appShots.count }

    public var heroShot: AppShot? { appShots.first }

    public var unconfiguredShots: [AppShot] {
        appShots.filter { !$0.isConfigured }
    }

    public var isReady: Bool {
        template != nil && palette != nil && appShots.allSatisfy(\.isConfigured)
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

/// Progress check for a gallery.
public struct GalleryReadiness: Sendable, Equatable {
    public let hasPalette: Bool
    public let hasTemplate: Bool
    public let configuredCount: Int
    public let totalCount: Int

    public var isReady: Bool { hasPalette && hasTemplate && configuredCount == totalCount }
    public var progress: String { "\(configuredCount)/\(totalCount) app shots configured" }
}
