import SwiftUI
import Domain

/// App selector pill — mirrors the HTML prototype's `.app-pill`.
/// Selected state uses blue accent background; each pill shows a status-colored dot.
struct AppPillView: View {
    let app: ASCApp
    let isSelected: Bool
    let statusColor: Color
    let onTap: () -> Void

    @Environment(\.appTheme) private var theme
    @State private var isHovering = false

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 6) {
                // Status dot
                Circle()
                    .fill(statusColor)
                    .frame(width: 6, height: 6)

                Text(app.displayName)
                    .font(.system(size: 12, weight: .semibold, design: theme.fontDesign))
                    .lineLimit(1)
                    .fixedSize()
            }
            .foregroundStyle(isSelected ? theme.textPrimary : theme.textSecondary)
            .padding(.horizontal, 12)
            .padding(.vertical, 5)
            .background(
                RoundedRectangle(cornerRadius: theme.pillCornerRadius)
                    .fill(
                        isSelected
                            ? theme.accentPrimary.opacity(0.15)
                            : (isHovering ? theme.hoverBackground : theme.glassBackground)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: theme.pillCornerRadius)
                            .stroke(
                                isSelected
                                    ? theme.accentPrimary.opacity(0.35)
                                    : Color.clear,
                                lineWidth: 1
                            )
                    )
            )
        }
        .buttonStyle(.plain)
        .onHover { isHovering = $0 }
    }
}
