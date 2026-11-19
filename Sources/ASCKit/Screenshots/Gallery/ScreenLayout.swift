import Foundation

/// Layout for a single screen type — where text and devices go.
///
/// Supports tagline (above headline), headline, subheading (below headline),
/// single device, side-by-side (2 devices), or triple fan (3 devices).
public struct ScreenLayout: Sendable, Equatable, Codable {
    public let tagline: TextSlot?
    public let headline: TextSlot
    public let subheading: TextSlot?
    public let devices: [DeviceSlot]
    public let decorations: [Decoration]

    public init(
        tagline: TextSlot? = nil,
        headline: TextSlot,
        subheading: TextSlot? = nil,
        devices: [DeviceSlot] = [],
        decorations: [Decoration] = []
    ) {
        self.tagline = tagline
        self.headline = headline
        self.subheading = subheading
        self.devices = devices
        self.decorations = decorations
    }

    /// Convenience: single device.
    public init(
        tagline: TextSlot? = nil,
        headline: TextSlot,
        subheading: TextSlot? = nil,
        device: DeviceSlot,
        decorations: [Decoration] = []
    ) {
        self.tagline = tagline
        self.headline = headline
        self.subheading = subheading
        self.devices = [device]
        self.decorations = decorations
    }

    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        tagline = try c.decodeIfPresent(TextSlot.self, forKey: .tagline)
        headline = try c.decode(TextSlot.self, forKey: .headline)
        subheading = try c.decodeIfPresent(TextSlot.self, forKey: .subheading)
        if let arr = try? c.decode([DeviceSlot].self, forKey: .devices) {
            devices = arr
        } else if let single = try? c.decode(DeviceSlot.self, forKey: .device) {
            devices = [single]
        } else {
            devices = []
        }
        decorations = try c.decodeIfPresent([Decoration].self, forKey: .decorations) ?? []
    }

    private enum CodingKeys: String, CodingKey {
        case tagline, headline, subheading, device, devices, decorations
    }

    public func encode(to encoder: any Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encodeIfPresent(tagline, forKey: .tagline)
        try c.encode(headline, forKey: .headline)
        try c.encodeIfPresent(subheading, forKey: .subheading)
        if !devices.isEmpty { try c.encode(devices, forKey: .devices) }
        if !decorations.isEmpty { try c.encode(decorations, forKey: .decorations) }
    }

    public var deviceCount: Int { devices.count }

    /// Return a copy with the given decorations (replaces existing).
    public func withDecorations(_ decorations: [Decoration]) -> ScreenLayout {
        ScreenLayout(
            tagline: tagline, headline: headline, subheading: subheading,
            devices: devices, decorations: decorations
        )
    }
}

/// A text position in a screen layout.
///
/// `preview` is the placeholder text shown in the template browser.
/// When the user applies the template, their AppShot content replaces it.
public struct TextSlot: Sendable, Equatable, Codable {
    public let y: Double
    public let size: Double
    public let weight: Int
    public let align: String
    public let preview: String?

    public init(y: Double, size: Double, weight: Int = 900, align: String = "center", preview: String? = nil) {
        self.y = y
        self.size = size
        self.weight = weight
        self.align = align
        self.preview = preview
    }

    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        y = try c.decode(Double.self, forKey: .y)
        size = try c.decode(Double.self, forKey: .size)
        weight = try c.decodeIfPresent(Int.self, forKey: .weight) ?? 900
        align = try c.decodeIfPresent(String.self, forKey: .align) ?? "center"
        preview = try c.decodeIfPresent(String.self, forKey: .preview)
    }
}

/// Where the device frame appears in a screen.
public struct DeviceSlot: Sendable, Equatable, Codable {
    public let x: Double
    public let y: Double
    public let width: Double

    public init(x: Double = 0.5, y: Double, width: Double) {
        self.x = x
        self.y = y
        self.width = width
    }
}

/// A decorative element — ambient shapes or text/emoji labels.
///
/// Positions (`x`, `y`) are normalized 0-1. `size` is relative to container width,
/// rendered as `cqi` units by `GalleryHTMLRenderer` for consistent scaling.
public struct Decoration: Sendable, Equatable, Codable {
    public let shape: DecorationShape
    public let x: Double
    public let y: Double
    public let size: Double
    public let opacity: Double
    /// Text/shape color (optional — renderer picks a default based on background).
    public let color: String?
    /// Pill background for label decorations (e.g. "rgba(255,255,255,0.1)").
    public let background: String?
    /// CSS border-radius for pill shape (e.g. "50%", "12px").
    public let borderRadius: String?
    /// Animation for movement (float, drift, pulse, spin, twinkle).
    public let animation: DecorationAnimation?

    public init(
        shape: DecorationShape, x: Double, y: Double, size: Double, opacity: Double = 1.0,
        color: String? = nil, background: String? = nil,
        borderRadius: String? = nil, animation: DecorationAnimation? = nil
    ) {
        self.shape = shape
        self.x = x
        self.y = y
        self.size = size
        self.opacity = opacity
        self.color = color
        self.background = background
        self.borderRadius = borderRadius
        self.animation = animation
    }

    private enum CodingKeys: String, CodingKey {
        case shape, x, y, size, opacity, color, background, borderRadius, animation
    }

    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        shape = try c.decode(DecorationShape.self, forKey: .shape)
        x = try c.decode(Double.self, forKey: .x)
        y = try c.decode(Double.self, forKey: .y)
        size = try c.decode(Double.self, forKey: .size)
        opacity = try c.decodeIfPresent(Double.self, forKey: .opacity) ?? 1.0
        color = try c.decodeIfPresent(String.self, forKey: .color)
        background = try c.decodeIfPresent(String.self, forKey: .background)
        borderRadius = try c.decodeIfPresent(String.self, forKey: .borderRadius)
        animation = try c.decodeIfPresent(DecorationAnimation.self, forKey: .animation)
    }

    public func encode(to encoder: any Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(shape, forKey: .shape)
        try c.encode(x, forKey: .x)
        try c.encode(y, forKey: .y)
        try c.encode(size, forKey: .size)
        if opacity != 1.0 { try c.encode(opacity, forKey: .opacity) }
        try c.encodeIfPresent(color, forKey: .color)
        try c.encodeIfPresent(background, forKey: .background)
        try c.encodeIfPresent(borderRadius, forKey: .borderRadius)
        try c.encodeIfPresent(animation, forKey: .animation)
    }
}

/// Shape type for decorations.
///
/// Simple shapes (gem, orb, sparkle, arrow) render as CSS shapes.
/// Labels render as text/emoji with optional pill background.
public enum DecorationShape: Sendable, Equatable, Codable {
    case gem, orb, sparkle, arrow
    case label(String)

    /// The display character for this shape.
    public var displayCharacter: String {
        switch self {
        case .label(let text): text
        case .gem: "◆"
        case .orb: "●"
        case .sparkle: "✦"
        case .arrow: "›"
        }
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        // Try string first (simple shapes: "gem", "orb", etc.)
        if let raw = try? container.decode(String.self) {
            switch raw {
            case "gem": self = .gem
            case "orb": self = .orb
            case "sparkle": self = .sparkle
            case "arrow": self = .arrow
            default: self = .label(raw)
            }
            return
        }
        // Try {"label": "text"} format
        let dict = try container.decode([String: String].self)
        if let text = dict["label"] {
            self = .label(text)
        } else {
            self = .gem
        }
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .gem: try container.encode("gem")
        case .orb: try container.encode("orb")
        case .sparkle: try container.encode("sparkle")
        case .arrow: try container.encode("arrow")
        case .label(let text): try container.encode(["label": text])
        }
    }
}

/// Animation type for decorative elements.
public enum DecorationAnimation: String, Sendable, Equatable, Codable {
    case float, drift, pulse, spin, twinkle
}
