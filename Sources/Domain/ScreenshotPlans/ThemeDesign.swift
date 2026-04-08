import Foundation

/// A structured theme design that can be applied deterministically to any template.
///
/// Composes from Gallery-native types:
/// - `GalleryPalette` for background + textColor
/// - `[Decoration]` for floating elements (label shapes with cqi sizing)
///
/// Returned by AI once, then reused across all screenshots without additional AI calls.
/// Applied via `ThemeDesignApplier`, which re-renders through `GalleryHTMLRenderer.renderScreen()`
/// — the same pipeline used by templates and galleries.
public struct ThemeDesign: Sendable, Equatable, Codable {
    /// Palette with background and optional textColor override.
    public let palette: GalleryPalette
    /// Decorative floating elements (label shapes with normalized 0-1 positions).
    public let decorations: [Decoration]

    public init(palette: GalleryPalette, decorations: [Decoration]) {
        self.palette = palette
        self.decorations = decorations
    }
}
