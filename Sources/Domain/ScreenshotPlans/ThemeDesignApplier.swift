import Foundation

/// Deterministically applies a `ThemeDesign` to a shot + layout.
///
/// Instead of patching HTML post-hoc, re-renders through the standard
/// `GalleryHTMLRenderer.renderScreen()` pipeline with an overridden palette
/// and merged decorations. This ensures consistent `cqi` sizing and
/// identical rendering behavior as templates and galleries.
public enum ThemeDesignApplier {

    /// Apply a ThemeDesign by re-rendering with overridden palette and merged decorations.
    ///
    /// - Parameters:
    ///   - design: The theme design (palette + decorations)
    ///   - shot: The app shot with content (headline, screenshot, etc.)
    ///   - screenLayout: The template's screen layout
    /// - Returns: Themed HTML fragment
    public static func apply(
        _ design: ThemeDesign,
        shot: AppShot,
        screenLayout: ScreenLayout
    ) -> String {
        let themedLayout = screenLayout.withDecorations(
            screenLayout.decorations + design.decorations
        )
        return GalleryHTMLRenderer.renderScreen(shot, screenLayout: themedLayout, palette: design.palette)
    }
}
