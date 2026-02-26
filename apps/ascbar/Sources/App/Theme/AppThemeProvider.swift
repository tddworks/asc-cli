import SwiftUI
import Domain

// MARK: - Protocol

/// Defines all visual properties a theme must provide.
/// Follows the same pluggable pattern as claudebar's theme system.
public protocol AppThemeProvider: Sendable {
    var id: String { get }
    var displayName: String { get }
    var icon: String { get }

    // Background
    var backgroundGradient: LinearGradient { get }
    var showBackgroundOrbs: Bool { get }

    // Cards & Glass
    var cardGradient: LinearGradient { get }
    var glassBackground: Color { get }
    var glassBorder: Color { get }
    var glassHighlight: Color { get }
    var cardCornerRadius: CGFloat { get }
    var pillCornerRadius: CGFloat { get }

    // Typography
    var textPrimary: Color { get }
    var textSecondary: Color { get }
    var textTertiary: Color { get }
    var fontDesign: Font.Design { get }

    // Status
    var statusLive: Color { get }
    var statusEditable: Color { get }
    var statusPending: Color { get }
    var statusRemoved: Color { get }
    var statusProcessing: Color { get }

    // Accents
    var accentPrimary: Color { get }
    var accentSecondary: Color { get }
    var accentGradient: LinearGradient { get }
    var pillGradient: LinearGradient { get }
    var shareGradient: LinearGradient { get }

    // Interactive
    var hoverOverlay: Color { get }
    var pressedOverlay: Color { get }
    var progressTrack: Color { get }
}

// MARK: - Default Helpers

public extension AppThemeProvider {
    func statusColor(for status: AppStatus) -> Color {
        switch status {
        case .live:       return statusLive
        case .editable:   return statusEditable
        case .pending:    return statusPending
        case .removed:    return statusRemoved
        case .processing: return statusProcessing
        }
    }

    func progressGradient(for status: AppStatus) -> LinearGradient {
        let color = statusColor(for: status)
        return LinearGradient(colors: [color.opacity(0.8), color], startPoint: .leading, endPoint: .trailing)
    }
}

// MARK: - Base Colors (mirrors ClaudeBar's BaseTheme)

public enum BaseColors {
    // Status
    public static let green   = Color(red: 0.35, green: 0.92, blue: 0.68)
    public static let amber   = Color(red: 0.98, green: 0.72, blue: 0.35)
    public static let coral   = Color(red: 0.98, green: 0.55, blue: 0.45)
    public static let teal    = Color(red: 0.35, green: 0.85, blue: 0.78)
    public static let red     = Color(red: 0.98, green: 0.42, blue: 0.52)
    public static let blue    = Color(red: 0.38, green: 0.62, blue: 0.98)
    public static let purple  = Color(red: 0.55, green: 0.32, blue: 0.85)
    public static let gray    = Color(red: 0.55, green: 0.55, blue: 0.60)

    // Extended (matching ClaudeBar's BaseTheme)
    public static let purpleVibrant = Color(red: 0.55, green: 0.32, blue: 0.85)
    public static let pinkHot       = Color(red: 0.85, green: 0.35, blue: 0.65)
    public static let coralAccent   = Color(red: 0.98, green: 0.55, blue: 0.45)
    public static let goldenGlow    = Color(red: 0.98, green: 0.78, blue: 0.35)
    public static let tealBright    = Color(red: 0.35, green: 0.85, blue: 0.78)
}