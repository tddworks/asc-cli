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

/// An ambient decorative shape (gem, orb, sparkle, arrow).
public struct Decoration: Sendable, Equatable, Codable {
    public let shape: DecorationShape
    public let x: Double
    public let y: Double
    public let size: Double
    public let opacity: Double

    public init(shape: DecorationShape, x: Double, y: Double, size: Double, opacity: Double = 1.0) {
        self.shape = shape
        self.x = x
        self.y = y
        self.size = size
        self.opacity = opacity
    }
}

public enum DecorationShape: String, Sendable, Equatable, Codable {
    case gem, orb, sparkle, arrow
}
