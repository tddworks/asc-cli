import SwiftUI
import Domain

// MARK: - Protocol

/// Defines all visual properties a theme must provide.
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
    var textMono: Color { get }
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

    // Interactive
    var hoverBackground: Color { get }
    var pressedBackground: Color { get }
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

    /// Tinted card background color for a version card — matches the HTML prototype's state-tinted cards.
    func versionCardBackground(for status: AppStatus) -> Color {
        statusColor(for: status).opacity(0.07)
    }

    func versionCardBorder(for status: AppStatus) -> Color {
        statusColor(for: status).opacity(0.22)
    }

    func progressGradient(for status: AppStatus) -> LinearGradient {
        let c = statusColor(for: status)
        return LinearGradient(colors: [c.opacity(0.8), c], startPoint: .leading, endPoint: .trailing)
    }
}

// MARK: - Base Colors (macOS System Colors — matching ux-prototype.html)

public enum BaseColors {
    // macOS / iOS system palette
    public static let systemBlue   = Color(red: 0.039, green: 0.518, blue: 1.000) // #0a84ff
    public static let systemGreen  = Color(red: 0.188, green: 0.820, blue: 0.345) // #30d158
    public static let systemOrange = Color(red: 1.000, green: 0.624, blue: 0.039) // #ff9f0a
    public static let systemRed    = Color(red: 1.000, green: 0.271, blue: 0.227) // #ff453a
    public static let systemPurple = Color(red: 0.749, green: 0.353, blue: 0.949) // #bf5af2

    // Brand gradient (logo + primary buttons)
    public static let brandPurple  = Color(red: 0.482, green: 0.353, blue: 0.961) // #7b5af5
    public static let brandPink    = Color(red: 0.780, green: 0.290, blue: 0.969) // #c74af7

    // Neutral
    public static let gray = Color(red: 0.55, green: 0.55, blue: 0.60)

    // Legacy aliases
    public static let green   = systemGreen
    public static let amber   = systemOrange
    public static let coral   = Color(red: 0.98, green: 0.55, blue: 0.45)
    public static let teal    = Color(red: 0.35, green: 0.85, blue: 0.78)
    public static let red     = systemRed
    public static let blue    = systemBlue
    public static let purple  = systemPurple
    public static let purpleVibrant = brandPurple
    public static let pinkHot       = brandPink
    public static let coralAccent   = Color(red: 0.98, green: 0.55, blue: 0.45)
    public static let goldenGlow    = Color(red: 0.98, green: 0.78, blue: 0.35)
}
