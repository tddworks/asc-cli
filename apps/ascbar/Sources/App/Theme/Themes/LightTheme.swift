import SwiftUI

/// Light theme — clean white/grey with system-color accents.
public struct LightTheme: AppThemeProvider {
    public var id: String { "light" }
    public var displayName: String { "Light" }
    public var icon: String { "sun.max.fill" }

    public var backgroundGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color(red: 0.97, green: 0.97, blue: 0.97),
                Color(red: 0.93, green: 0.93, blue: 0.95),
            ],
            startPoint: .topLeading, endPoint: .bottomTrailing
        )
    }

    public var showBackgroundOrbs: Bool { false }

    public var cardGradient: LinearGradient {
        LinearGradient(
            colors: [Color.white.opacity(0.90), Color.white.opacity(0.70)],
            startPoint: .top, endPoint: .bottom
        )
    }

    public var glassBackground: Color { Color.white.opacity(0.80) }
    public var glassBorder: Color     { Color.black.opacity(0.08) }
    public var glassHighlight: Color  { Color.white }

    public var cardCornerRadius: CGFloat { 10 }
    public var pillCornerRadius: CGFloat { 20 }

    public var textPrimary: Color   { Color(red: 0.10, green: 0.10, blue: 0.12) }
    public var textSecondary: Color { Color(red: 0.40, green: 0.40, blue: 0.44) }
    public var textTertiary: Color  { Color(red: 0.62, green: 0.62, blue: 0.65) }
    public var textMono: Color      { Color(red: 0.0, green: 0.48, blue: 0.80) }

    public var fontDesign: Font.Design { .default }

    public var statusLive: Color       { Color(red: 0.18, green: 0.72, blue: 0.34) }
    public var statusEditable: Color   { Color(red: 0.00, green: 0.48, blue: 0.98) }
    public var statusPending: Color    { Color(red: 0.88, green: 0.55, blue: 0.00) }
    public var statusRemoved: Color    { Color(red: 0.90, green: 0.22, blue: 0.18) }
    public var statusProcessing: Color { Color(red: 0.55, green: 0.55, blue: 0.58) }

    public var accentPrimary: Color   { Color(red: 0.00, green: 0.48, blue: 0.98) }
    public var accentSecondary: Color { Color(red: 0.45, green: 0.22, blue: 0.85) }

    public var accentGradient: LinearGradient {
        LinearGradient(
            colors: [BaseColors.brandPurple, BaseColors.brandPink],
            startPoint: .topLeading, endPoint: .bottomTrailing
        )
    }

    public var pillGradient: LinearGradient {
        LinearGradient(
            colors: [Color.black.opacity(0.05), Color.black.opacity(0.02)],
            startPoint: .top, endPoint: .bottom
        )
    }

    public var hoverBackground: Color   { Color.black.opacity(0.04) }
    public var pressedBackground: Color { Color.black.opacity(0.08) }
    public var progressTrack: Color     { Color.black.opacity(0.08) }
}
