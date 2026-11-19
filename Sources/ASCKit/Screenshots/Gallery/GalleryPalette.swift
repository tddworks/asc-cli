import Foundation

/// The color scheme for a gallery — HOW things look.
///
/// Controls background, text colors, badge styling, decoration tints.
/// Same palette works with any template layout.
public struct GalleryPalette: Sendable, Equatable, Identifiable, Codable {
    public let id: String
    public let name: String
    public let background: String
    /// Explicit primary text color. When set, overrides the auto-detect heuristic.
    public let textColor: String?

    public init(
        id: String,
        name: String,
        background: String,
        textColor: String? = nil
    ) {
        self.id = id
        self.name = name
        self.background = background
        self.textColor = textColor
    }

    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        name = try c.decode(String.self, forKey: .name)
        background = try c.decode(String.self, forKey: .background)
        textColor = try c.decodeIfPresent(String.self, forKey: .textColor)
    }
}

// MARK: - Theme Detection

extension GalleryPalette {

    /// Whether this palette has a light background (heuristic based on hex values).
    public var isLight: Bool {
        guard textColor == nil else { return false }
        let lightHex = ["#f", "#F", "#e", "#E", "#d", "#D", "#c", "#C", "#b", "#B", "#a8", "#A8", "#9"]
        return lightHex.contains(where: { background.contains($0) })
    }

    /// Primary text color — explicit or auto-detected from background.
    public var headlineColor: String { textColor ?? (isLight ? "#000" : "#fff") }
}
