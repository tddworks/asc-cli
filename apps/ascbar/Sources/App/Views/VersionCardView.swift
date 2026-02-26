import SwiftUI
import Domain

/// Compact version card — mirrors the HTML prototype's `.version-card` exactly.
/// State-tinted background, hover-reveal "Open details" affordance.
struct VersionCardView: View {
    let version: ASCVersion
    /// Called when the user taps the card to open version detail.
    var onTapDetail: ((ASCVersion) -> Void)?

    @Environment(\.appTheme) private var theme
    @State private var isHovering = false

    var body: some View {
        Button(action: tapAction) {
            VStack(alignment: .leading, spacing: 4) {
                // Platform label — 9px uppercase glass badge
                Text(version.platformDisplayName.uppercased())
                    .font(.system(size: 9, weight: .bold, design: theme.fontDesign))
                    .foregroundStyle(theme.textTertiary)
                    .tracking(0.5)
                    .padding(.horizontal, 5)
                    .padding(.vertical, 1)
                    .background(
                        RoundedRectangle(cornerRadius: 3)
                            .fill(theme.glassBackground)
                    )

                // Version number — 18px bold
                Text(version.versionString)
                    .font(.system(size: 18, weight: .bold, design: theme.fontDesign))
                    .foregroundStyle(theme.textPrimary)
                    .lineLimit(1)

                // State — colored by status
                Text(version.stateDisplayName)
                    .font(.system(size: 11, weight: .semibold, design: theme.fontDesign))
                    .foregroundStyle(statusColor)
                    .lineLimit(1)

                // Hover affordance — appears on hover
                if isHovering {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.up.right.square")
                            .font(.system(size: 9, weight: .semibold))
                        Text("Open details")
                            .font(.system(size: 10, weight: .semibold, design: theme.fontDesign))
                    }
                    .foregroundStyle(theme.accentPrimary)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                }
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(cardBackground)
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(.easeOut(duration: 0.12)) { isHovering = hovering }
        }
    }

    // MARK: - Card Background

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: theme.cardCornerRadius)
            .fill(isHovering ? theme.hoverBackground : theme.versionCardBackground(for: version.appStatus))
            .overlay(
                RoundedRectangle(cornerRadius: theme.cardCornerRadius)
                    .stroke(
                        isHovering
                            ? statusColor.opacity(0.5)
                            : theme.versionCardBorder(for: version.appStatus),
                        lineWidth: isHovering ? 1.5 : 1
                    )
            )
    }

    private func tapAction() {
        onTapDetail?(version)
    }

    private var statusColor: Color {
        theme.statusColor(for: version.appStatus)
    }
}
