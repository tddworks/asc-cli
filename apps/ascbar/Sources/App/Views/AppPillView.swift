import SwiftUI
import Domain

/// A tappable pill for selecting an app — styled after ClaudeBar's ProviderPill.
/// Selected state uses the accent gradient fill with a drop shadow.
struct AppPillView: View {
    let app: ASCApp
    let isSelected: Bool
    let onTap: () -> Void

    @Environment(\.appTheme) private var theme
    @State private var isHovering = false

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 4) {
                Image(systemName: "app.fill")
                    .font(.system(size: 10, weight: .semibold))

                Text(app.displayName)
                    .font(.system(size: 11, weight: .medium, design: theme.fontDesign))
                    .lineLimit(1)
                    .fixedSize()
            }
            .foregroundStyle(isSelected ? .white : theme.textPrimary)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                ZStack {
                    if isSelected {
                        RoundedRectangle(cornerRadius: theme.pillCornerRadius)
                            .fill(theme.accentGradient)
                            .shadow(color: theme.accentPrimary.opacity(0.3), radius: 6, y: 2)
                    } else {
                        RoundedRectangle(cornerRadius: theme.pillCornerRadius)
                            .fill(isHovering ? theme.hoverOverlay : theme.glassBackground)
                    }
                    RoundedRectangle(cornerRadius: theme.pillCornerRadius)
                        .stroke(isSelected ? theme.accentPrimary.opacity(0.5) : theme.glassBorder, lineWidth: 1)
                }
            )
        }
        .buttonStyle(.plain)
        .onHover { isHovering = $0 }
    }
}
