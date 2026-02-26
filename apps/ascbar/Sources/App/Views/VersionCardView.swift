import SwiftUI
import Domain

/// Displays a single app version as a rich status card — modelled after ClaudeBar's WrappedStatCard.
/// Shows platform label + status badge in the header, large version number, state description,
/// an animated status bar, and a footer with the last-checked time.
struct VersionCardView: View {
    let version: ASCVersion

    @Environment(\.appTheme) private var theme
    @State private var isHovering = false
    @State private var animateProgress = false

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            headerRow
            versionNumber
            progressBar
            footerRow
        }
        .padding(12)
        .background(cardBackground)
        .scaleEffect(isHovering ? 1.015 : 1.0)
        .animation(.easeOut(duration: 0.15), value: isHovering)
        .onHover { isHovering = $0 }
        .onAppear { animateProgress = true }
    }

    // MARK: - Header Row

    private var headerRow: some View {
        HStack(alignment: .top, spacing: 0) {
            // Left: platform icon + platform label
            HStack(spacing: 5) {
                Image(systemName: platformIcon)
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(statusColor)

                Text(version.platformDisplayName.uppercased())
                    .font(.system(size: 8, weight: .medium, design: theme.fontDesign))
                    .foregroundStyle(theme.textSecondary)
                    .tracking(0.3)
            }

            Spacer(minLength: 4)

            // Right: status badge
            Text(statusBadgeText)
                .font(.system(size: 8, weight: .semibold, design: theme.fontDesign))
                .foregroundStyle(statusColor)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(
                    Capsule()
                        .fill(statusColor.opacity(0.15))
                        .overlay(Capsule().stroke(statusColor.opacity(0.4), lineWidth: 0.5))
                )
        }
    }

    // MARK: - Version Number

    private var versionNumber: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(version.versionString)
                .font(.system(size: 28, weight: .bold, design: theme.fontDesign))
                .foregroundStyle(theme.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.6)

            Spacer()

            Text(version.stateDisplayName)
                .font(.system(size: 11, weight: .medium, design: theme.fontDesign))
                .foregroundStyle(theme.textTertiary)
                .lineLimit(1)
                .multilineTextAlignment(.trailing)
        }
    }

    // MARK: - Progress Bar

    private var progressBar: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 3)
                    .fill(theme.progressTrack)

                RoundedRectangle(cornerRadius: 3)
                    .fill(theme.progressGradient(for: version.appStatus))
                    .frame(
                        width: animateProgress
                            ? geo.size.width * statusProgressFraction
                            : 0
                    )
                    .animation(
                        .spring(response: 0.8, dampingFraction: 0.7).delay(0.2),
                        value: animateProgress
                    )
            }
        }
        .frame(height: 5)
    }

    // MARK: - Footer

    private var footerRow: some View {
        HStack(spacing: 3) {
            Image(systemName: "app.badge.checkmark")
                .font(.system(size: 7))

            Text(version.buildId == nil ? "No build attached" : "Build attached")
                .font(.system(size: 8, weight: .medium, design: theme.fontDesign))
        }
        .foregroundStyle(theme.textTertiary)
        .lineLimit(1)
    }

    // MARK: - Card Background

    private var cardBackground: some View {
        ZStack {
            RoundedRectangle(cornerRadius: theme.cardCornerRadius)
                .fill(theme.cardGradient)
            RoundedRectangle(cornerRadius: theme.cardCornerRadius)
                .stroke(theme.glassBorder, lineWidth: 1)
        }
    }

    // MARK: - Helpers

    private var statusColor: Color {
        theme.statusColor(for: version.appStatus)
    }

    private var statusBadgeText: String {
        switch version.appStatus {
        case .live:       return "LIVE"
        case .editable:   return "EDIT"
        case .pending:    return "REVIEW"
        case .removed:    return "REMOVED"
        case .processing: return "PROCESSING"
        }
    }

    private var platformIcon: String {
        switch version.platform {
        case "IOS":       return "iphone"
        case "MAC_OS":    return "desktopcomputer"
        case "TV_OS":     return "tv"
        case "WATCH_OS":  return "applewatch"
        case "VISION_OS": return "visionpro"
        default:          return "app"
        }
    }

    /// Progress bar fill fraction (0–1) based on version lifecycle position.
    private var statusProgressFraction: CGFloat {
        switch version.appStatus {
        case .live:       return 1.0
        case .pending:    return 0.65
        case .editable:   return 0.20
        case .removed:    return 0.0
        case .processing: return 0.40
        }
    }
}