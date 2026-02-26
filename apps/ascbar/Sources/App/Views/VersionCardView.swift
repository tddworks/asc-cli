import SwiftUI
import Domain

/// Compact version card — mirrors the HTML prototype's `.version-card` exactly.
/// State-tinted background, hover-reveal "Copy [action]" affordance.
struct VersionCardView: View {
    let version: ASCVersion
    /// Called when the user clicks the hover affordance — provides the CLI command to copy.
    var onCopyCommand: ((String) -> Void)?

    @Environment(\.appTheme) private var theme
    @State private var isHovering = false

    var body: some View {
        Button(action: copyAction) {
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
                if isHovering, let label = affordanceLabel {
                    HStack(spacing: 4) {
                        Image(systemName: "doc.on.doc")
                            .font(.system(size: 9, weight: .semibold))
                        Text(label)
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

    // MARK: - Affordance

    /// The hover label for the copy action — nil for non-actionable states.
    private var affordanceLabel: String? {
        switch version.appStatus {
        case .editable:   return "Copy submit"
        case .live:       return "Copy cmd"
        case .pending:    return "Copy status"
        case .removed, .processing: return nil
        }
    }

    /// The CLI command that gets copied on tap.
    private var cliCommand: String? {
        switch version.appStatus {
        case .editable:
            return "asc versions submit --version-id \(version.id)"
        case .live:
            return "asc versions list --app-id \(version.appId)"
        case .pending:
            return "asc builds list --app-id \(version.appId)"
        case .removed, .processing:
            return nil
        }
    }

    private func copyAction() {
        guard let cmd = cliCommand else { return }
        onCopyCommand?(cmd)
    }

    private var statusColor: Color {
        theme.statusColor(for: version.appStatus)
    }
}
