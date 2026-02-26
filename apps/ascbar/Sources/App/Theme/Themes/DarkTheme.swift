import SwiftUI

/// Dark theme — macOS dark vibrancy.
/// Colors match ux-prototype.html exactly: near-black base, iOS system status colors,
/// purple-pink brand gradient for the logo and primary buttons.
public struct DarkTheme: AppThemeProvider {
    public var id: String { "dark" }
    public var displayName: String { "Dark" }
    public var icon: String { "moon.stars.fill" }

    // MARK: - Background

    public var backgroundGradient: LinearGradient {
        // --bg-base: #1e1e20  →  #252528
        LinearGradient(
            colors: [
                Color(red: 0.118, green: 0.118, blue: 0.125),
                Color(red: 0.145, green: 0.145, blue: 0.157),
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    public var showBackgroundOrbs: Bool { true }

    // MARK: - Cards & Glass

    public var cardGradient: LinearGradient {
        // Flat glass card — matches --bg-card: rgba(255,255,255,0.06)
        LinearGradient(
            colors: [Color.white.opacity(0.06), Color.white.opacity(0.04)],
            startPoint: .top, endPoint: .bottom
        )
    }

    public var glassBackground: Color { Color.white.opacity(0.06) }   // --bg-card
    public var glassBorder: Color     { Color.white.opacity(0.10) }   // --border
    public var glassHighlight: Color  { Color.white.opacity(0.20) }   // --border-focus

    public var cardCornerRadius: CGFloat { 10 }   // --radius-card
    public var pillCornerRadius: CGFloat { 20 }   // --radius-pill

    // MARK: - Typography

    public var textPrimary: Color   { Color.white.opacity(0.92) }   // --text-primary
    public var textSecondary: Color { Color.white.opacity(0.50) }   // --text-secondary
    public var textTertiary: Color  { Color.white.opacity(0.28) }   // --text-tertiary
    public var textMono: Color      { Color(red: 0.392, green: 0.824, blue: 1.0).opacity(0.85) } // --text-mono #64d2ff

    public var fontDesign: Font.Design { .default }   // SF Pro (not rounded)

    // MARK: - Status Colors (iOS system palette)

    public var statusLive: Color       { BaseColors.systemGreen }   // #30d158
    public var statusEditable: Color   { BaseColors.systemBlue }    // #0a84ff  (Prepare for Submission)
    public var statusPending: Color    { BaseColors.systemOrange }  // #ff9f0a  (In Review)
    public var statusRemoved: Color    { BaseColors.systemRed }     // #ff453a
    public var statusProcessing: Color { BaseColors.gray }

    // MARK: - Accents

    public var accentPrimary: Color   { BaseColors.systemBlue }     // #0a84ff — pills, links, selection
    public var accentSecondary: Color { BaseColors.systemPurple }   // #bf5af2

    public var accentGradient: LinearGradient {
        // Purple-pink brand gradient — logo circle + "Apps" primary button
        LinearGradient(
            colors: [BaseColors.brandPurple, BaseColors.brandPink],
            startPoint: .topLeading, endPoint: .bottomTrailing
        )
    }

    public var pillGradient: LinearGradient {
        LinearGradient(
            colors: [Color.white.opacity(0.08), Color.white.opacity(0.04)],
            startPoint: .top, endPoint: .bottom
        )
    }

    // MARK: - Interactive

    public var hoverBackground: Color   { Color.white.opacity(0.10) }  // --bg-card-hover
    public var pressedBackground: Color { Color.white.opacity(0.14) }
    public var progressTrack: Color     { Color.white.opacity(0.10) }
}
