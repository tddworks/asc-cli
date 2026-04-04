import Foundation

/// A reusable template for composing App Store screenshots.
///
/// Templates define the visual layout: background, text positions, and device placement.
/// Users pick a template, fill in their content (headline, subtitle, screenshot),
/// and produce a `ScreenshotDesign` ready for generation.
///
/// Plugins (like Blitz) register their own templates via `TemplateRepository`.
public struct ScreenshotTemplate: Sendable, Equatable, Identifiable, Codable {
    public let id: String
    public let name: String
    public let category: TemplateCategory
    public let supportedSizes: [ScreenSize]
    public let description: String
    public let background: SlideBackground
    public let textSlots: [TemplateTextSlot]
    public let deviceSlots: [TemplateDeviceSlot]

    public init(
        id: String,
        name: String,
        category: TemplateCategory,
        supportedSizes: [ScreenSize],
        description: String,
        background: SlideBackground,
        textSlots: [TemplateTextSlot],
        deviceSlots: [TemplateDeviceSlot]
    ) {
        self.id = id
        self.name = name
        self.category = category
        self.supportedSizes = supportedSizes
        self.description = description
        self.background = background
        self.textSlots = textSlots
        self.deviceSlots = deviceSlots
    }

    /// Self-contained HTML page previewing this template with default sample text.
    public var previewHTML: String {
        TemplateHTMLRenderer.renderPage(self)
    }
}

// MARK: - Semantic Booleans

extension ScreenshotTemplate {
    /// Whether this template supports portrait orientation.
    public var isPortrait: Bool { supportedSizes.contains(.portrait) }

    /// Whether this template supports landscape orientation.
    public var isLandscape: Bool { supportedSizes.contains(.landscape) }

    /// Number of device slots in this template.
    public var deviceCount: Int { deviceSlots.count }
}

// MARK: - Affordances

extension ScreenshotTemplate: AffordanceProviding {
    public var affordances: [String: String] {
        [
            "previewHTML": previewHTML,
            "apply": "asc app-shots templates apply --id \(id) --screenshot screen.png",
            "detail": "asc app-shots templates get --id \(id)",
            "listAll": "asc app-shots templates list",
        ]
    }
}

// MARK: - Supporting Types

/// Template category for filtering and organization.
public enum TemplateCategory: String, Sendable, Equatable, Codable, CaseIterable {
    case bold
    case minimal
    case elegant
    case professional
    case playful
    case showcase
    case custom
}

/// Screen size/orientation category for template compatibility.
public enum ScreenSize: String, Sendable, Equatable, Codable, CaseIterable {
    case portrait       // Tall phone (9:19+)
    case portrait43     // iPad-like (3:4)
    case landscape      // Wide (16:9, Mac)
    case square         // 1:1
}

/// A text slot in a template — defines where text appears and its default content.
public struct TemplateTextSlot: Sendable, Equatable, Codable {
    /// The role this text plays (heading, subheading, tagline).
    public let role: TextRole
    /// Default preview text shown in template browser.
    public let preview: String
    /// Horizontal position (0–1, normalized to canvas width).
    public let x: Double
    /// Vertical position (0–1, normalized to canvas height).
    public let y: Double
    /// Font size relative to canvas width (0.1 = 10%).
    public let fontSize: Double
    /// Font weight (100–900).
    public let fontWeight: Int
    /// Text color (hex or rgba).
    public let color: String
    /// Text alignment.
    public let textAlign: String
    /// Optional font family override.
    public let font: String?
    /// Optional letter spacing.
    public let letterSpacing: String?
    /// Optional line height.
    public let lineHeight: Double?
    /// Optional text transform (uppercase, etc.).
    public let textTransform: String?
    /// Optional font style (italic, etc.).
    public let fontStyle: String?

    public init(
        role: TextRole,
        preview: String,
        x: Double, y: Double,
        fontSize: Double,
        fontWeight: Int = 700,
        color: String,
        textAlign: String = "center",
        font: String? = nil,
        letterSpacing: String? = nil,
        lineHeight: Double? = nil,
        textTransform: String? = nil,
        fontStyle: String? = nil
    ) {
        self.role = role
        self.preview = preview
        self.x = x
        self.y = y
        self.fontSize = fontSize
        self.fontWeight = fontWeight
        self.color = color
        self.textAlign = textAlign
        self.font = font
        self.letterSpacing = letterSpacing
        self.lineHeight = lineHeight
        self.textTransform = textTransform
        self.fontStyle = fontStyle
    }
}

/// The role a text slot plays in a template.
public enum TextRole: String, Sendable, Equatable, Codable {
    case heading
    case subheading
    case tagline
}

/// A device slot in a template — defines where a screenshot device appears.
public struct TemplateDeviceSlot: Sendable, Equatable, Codable {
    /// Center X position (0–1).
    public let x: Double
    /// Top Y position (0–1).
    public let y: Double
    /// Width relative to canvas (0–1).
    public let scale: Double
    /// Rotation in degrees.
    public let rotation: Double?
    /// Z-index for overlapping devices.
    public let zIndex: Int?

    public init(
        x: Double, y: Double,
        scale: Double,
        rotation: Double? = nil,
        zIndex: Int? = nil
    ) {
        self.x = x
        self.y = y
        self.scale = scale
        self.rotation = rotation
        self.zIndex = zIndex
    }
}
