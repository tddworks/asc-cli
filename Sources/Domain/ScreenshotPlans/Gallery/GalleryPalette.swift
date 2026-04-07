import Foundation

/// The color scheme for a gallery — HOW things look.
///
/// Controls background, text colors, badge styling, decoration tints.
/// Same palette works with any template layout.
public struct GalleryPalette: Sendable, Equatable, Identifiable {
    public let id: String
    public let name: String
    public let background: String

    public init(
        id: String,
        name: String,
        background: String
    ) {
        self.id = id
        self.name = name
        self.background = background
    }
}
