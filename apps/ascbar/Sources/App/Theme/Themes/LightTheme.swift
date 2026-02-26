import SwiftUI

/// Light theme — soft lavender-white gradient, matching ClaudeBar's light aesthetic.
public struct LightTheme: AppThemeProvider {
    public var id: String { "light" }
    public var displayName: String { "Light" }
    public var icon: String { "sun.max.fill" }

    public var backgroundGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color(red: 0.98, green: 0.96, blue: 1.00),
                Color(red: 0.94, green: 0.92, blue: 0.98),
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    public var showBackgroundOrbs: Bool { true }

    public var cardGradient: LinearGradient {
        LinearGradient(
            colors: [Color.white.opacity(0.90), Color.white.opacity(0.70)],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    public var glassBackground: Color  { Color.white.opacity(0.80) }
    public var glassBorder: Color      { Color.black.opacity(0.08) }
    public var glassHighlight: Color   { Color.white }
    public var cardCornerRadius: CGFloat  { 14 }
    public var pillCornerRadius: CGFloat  { 20 }

    public var textPrimary: Color    { Color(red: 0.15, green: 0.12, blue: 0.22) }
    public var textSecondary: Color  { Color(red: 0.35, green: 0.32, blue: 0.45) }
    public var textTertiary: Color   { Color(red: 0.55, green: 0.52, blue: 0.62) }
    public var fontDesign: Font.Design { .rounded }

    public var statusLive: Color       { Color(red: 0.18, green: 0.72, blue: 0.44) }
    public var statusEditable: Color   { Color(red: 0.85, green: 0.60, blue: 0.10) }
    public var statusPending: Color    { Color(red: 0.20, green: 0.45, blue: 0.90) }
    public var statusRemoved: Color    { Color(red: 0.85, green: 0.25, blue: 0.30) }
    public var statusProcessing: Color { Color(red: 0.50, green: 0.50, blue: 0.55) }

    public var accentPrimary: Color    { Color(red: 0.72, green: 0.25, blue: 0.55) }
    public var accentSecondary: Color  { Color(red: 0.45, green: 0.22, blue: 0.85) }

    public var accentGradient: LinearGradient {
        LinearGradient(
            colors: [accentPrimary, accentSecondary],
            startPoint: .leading,
            endPoint: .trailing
        )
    }

    public var pillGradient: LinearGradient {
        LinearGradient(
            colors: [Color.black.opacity(0.06), Color.black.opacity(0.03)],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    public var shareGradient: LinearGradient {
        LinearGradient(
            colors: [Color(red: 0.98, green: 0.78, blue: 0.35), accentPrimary],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    public var hoverOverlay: Color    { Color.black.opacity(0.04) }
    public var pressedOverlay: Color  { Color.black.opacity(0.08) }
    public var progressTrack: Color   { Color.black.opacity(0.08) }
}