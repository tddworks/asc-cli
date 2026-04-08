import Foundation

/// A single-screenshot template for App Store screenshots.
///
/// Wraps the unified `ScreenLayout` + `GalleryPalette` types
/// with metadata for filtering (category, supportedSizes).
///
/// ```
/// let tmpl = AppShotTemplate(id: "top-hero", name: "Top Hero",
///     category: .bold, supportedSizes: [.portrait],
///     screenLayout: ScreenLayout(headline: TextSlot(y: 0.04, size: 0.10),
///                                     device: DeviceSlot(y: 0.18, width: 0.85)),
///     palette: GalleryPalette(id: "top-hero", name: "Top Hero",
///                              background: "linear-gradient(150deg,#4338CA,#6D28D9)"))
/// ```
public struct AppShotTemplate: Sendable, Identifiable {
    public let id: String
    public let name: String
    public let category: TemplateCategory
    public let supportedSizes: [ScreenSize]
    public let description: String
    public let screenLayout: ScreenLayout
    public let palette: GalleryPalette
    public init(
        id: String,
        name: String,
        category: TemplateCategory = .custom,
        supportedSizes: [ScreenSize] = [.portrait],
        description: String = "",
        screenLayout: ScreenLayout,
        palette: GalleryPalette
    ) {
        self.id = id
        self.name = name
        self.category = category
        self.supportedSizes = supportedSizes
        self.description = description
        self.screenLayout = screenLayout
        self.palette = palette
    }

    /// Self-contained HTML preview — renders with TextSlot.preview placeholders.
    public var previewHTML: String {
        let shot = AppShot(screenshot: "", type: .feature)
        // Don't set any content — renderer falls back to TextSlot.preview
        let html = GalleryHTMLRenderer.renderScreen(shot, screenLayout: screenLayout, palette: palette)
        return GalleryHTMLRenderer.wrapPage(html)
    }

    /// Apply with user content — returns a full HTML page.
    public func apply(shot: AppShot, fillViewport: Bool = false) -> String {
        let html = GalleryHTMLRenderer.renderScreen(shot, screenLayout: screenLayout, palette: palette)
        return GalleryHTMLRenderer.wrapPage(html, fillViewport: fillViewport)
    }

    /// Render inner HTML fragment for composition pipelines.
    public func renderFragment(shot: AppShot) -> String {
        GalleryHTMLRenderer.renderScreen(shot, screenLayout: screenLayout, palette: palette)
    }
}

// MARK: - Semantic Booleans

extension AppShotTemplate {
    public var isPortrait: Bool { supportedSizes.contains(.portrait) }
    public var isLandscape: Bool { supportedSizes.contains(.landscape) }
    public var deviceCount: Int { screenLayout.deviceCount }
}

// MARK: - Equatable

extension AppShotTemplate: Equatable {
    public static func == (lhs: AppShotTemplate, rhs: AppShotTemplate) -> Bool {
        lhs.id == rhs.id && lhs.name == rhs.name && lhs.category == rhs.category
            && lhs.screenLayout == rhs.screenLayout && lhs.palette == rhs.palette
    }
}

// MARK: - Codable

extension AppShotTemplate: Codable {
    private enum CodingKeys: String, CodingKey {
        case id, name, category, supportedSizes, description
        case screenLayout, palette
        case previewHTML, deviceCount
    }

    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        name = try c.decode(String.self, forKey: .name)
        category = try c.decodeIfPresent(TemplateCategory.self, forKey: .category) ?? .custom
        supportedSizes = try c.decodeIfPresent([ScreenSize].self, forKey: .supportedSizes) ?? [.portrait]
        description = try c.decodeIfPresent(String.self, forKey: .description) ?? ""
        screenLayout = try c.decode(ScreenLayout.self, forKey: .screenLayout)
        palette = try c.decode(GalleryPalette.self, forKey: .palette)
    }

    public func encode(to encoder: any Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(name, forKey: .name)
        try c.encode(category, forKey: .category)
        try c.encode(supportedSizes, forKey: .supportedSizes)
        try c.encode(description, forKey: .description)
        try c.encode(screenLayout, forKey: .screenLayout)
        try c.encode(palette, forKey: .palette)
        try c.encode(previewHTML, forKey: .previewHTML)
        try c.encode(deviceCount, forKey: .deviceCount)
    }
}

// MARK: - Presentable

extension AppShotTemplate: Presentable {
    public static var tableHeaders: [String] {
        ["ID", "Name", "Category", "Devices"]
    }
    public var tableRow: [String] {
        [id, name, category.rawValue, "\(deviceCount)"]
    }
}

// MARK: - Affordances

extension AppShotTemplate: AffordanceProviding {
    public var affordances: [String: String] {
        [
            "preview": "asc app-shots templates get --id \(id) --preview",
            "apply": "asc app-shots templates apply --id \(id) --screenshot screen.png",
            "detail": "asc app-shots templates get --id \(id)",
            "listAll": "asc app-shots templates list",
        ]
    }
}

// MARK: - Supporting Types (kept for metadata)

public enum TemplateCategory: String, Sendable, Equatable, Codable, CaseIterable {
    case bold, minimal, elegant, professional, playful, showcase, custom
}

public enum ScreenSize: String, Sendable, Equatable, Codable, CaseIterable {
    case portrait, portrait43, landscape, square
}
