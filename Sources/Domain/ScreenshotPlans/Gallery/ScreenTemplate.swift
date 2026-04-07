import Foundation

/// Layout for a single screen type — where headline, device, badges go.
///
/// Used within a `GalleryTemplate` to define how each screen type is composed.
public struct ScreenTemplate: Sendable, Equatable, Codable {
    public let headline: TextSlot
    public let device: DeviceSlot?
    public let decorations: [Decoration]

    public init(
        headline: TextSlot,
        device: DeviceSlot? = nil,
        decorations: [Decoration] = []
    ) {
        self.headline = headline
        self.device = device
        self.decorations = decorations
    }

    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        headline = try c.decode(TextSlot.self, forKey: .headline)
        device = try c.decodeIfPresent(DeviceSlot.self, forKey: .device)
        decorations = try c.decodeIfPresent([Decoration].self, forKey: .decorations) ?? []
    }
}

/// Where and how text appears in a screen.
public struct TextSlot: Sendable, Equatable, Codable {
    public let y: Double
    public let size: Double
    public let weight: Int
    public let align: String

    public init(y: Double, size: Double, weight: Int = 900, align: String = "center") {
        self.y = y
        self.size = size
        self.weight = weight
        self.align = align
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
