import SwiftUI

/// Dark theme — default. Deep purple gradient with glassmorphism, matching ClaudeBar's dark aesthetic.
public struct DarkTheme: AppThemeProvider {
    public var id: String { "dark" }
    public var displayName: String { "Dark" }
    public var icon: String { "moon.stars.fill" }

    public var backgroundGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color(red: 0.12, green: 0.08, blue: 0.22),
                Color(red: 0.18, green: 0.10, blue: 0.28),
                Color(red: 0.22, green: 0.12, blue: 0.32),
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    public var showBackgroundOrbs: Bool { true }

    public var cardGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color.white.opacity(0.18),
                Color.white.opacity(0.08),
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    public var glassBackground: Color  { Color.white.opacity(0.12) }
    public var glassBorder: Color      { Color.white.opacity(0.25) }
    public var glassHighlight: Color   { Color.white.opacity(0.35) }
    public var cardCornerRadius: CGFloat  { 14 }
    public var pillCornerRadius: CGFloat  { 20 }

    public var textPrimary: Color    { Color.white.opacity(0.95) }
    public var textSecondary: Color  { Color.white.opacity(0.70) }
    public var textTertiary: Color   { Color.white.opacity(0.50) }
    public var fontDesign: Font.Design { .rounded }

    public var statusLive: Color       { BaseColors.green }
    public var statusEditable: Color   { BaseColors.amber }
    public var statusPending: Color    { BaseColors.blue }
    public var statusRemoved: Color    { BaseColors.red }
    public var statusProcessing: Color { BaseColors.gray }

    public var accentPrimary: Color    { BaseColors.pinkHot }
    public var accentSecondary: Color  { BaseColors.purpleVibrant }

    public var accentGradient: LinearGradient {
        LinearGradient(
            colors: [BaseColors.coralAccent, BaseColors.pinkHot],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    public var pillGradient: LinearGradient {
        LinearGradient(
            colors: [
                BaseColors.purpleVibrant.opacity(0.6),
                BaseColors.pinkHot.opacity(0.4),
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    public var shareGradient: LinearGradient {
        LinearGradient(
            colors: [BaseColors.goldenGlow, BaseColors.coralAccent],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    public var hoverOverlay: Color    { Color.white.opacity(0.08) }
    public var pressedOverlay: Color  { Color.white.opacity(0.12) }
    public var progressTrack: Color   { Color.white.opacity(0.15) }
}