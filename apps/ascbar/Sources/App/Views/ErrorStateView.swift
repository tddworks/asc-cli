import SwiftUI

/// Error / no-auth popover state — matches the prototype's state 3 exactly.
/// Red-tinted error box with the auth command, plus a "Set up credentials" row below.
struct ErrorStateView: View {
    var onCopy: ((String) -> Void)?

    @Environment(\.appTheme) private var theme

    var body: some View {
        VStack(spacing: 8) {
            errorBox
            credentialsRow
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    // MARK: - Red-tinted error box

    private var errorBox: some View {
        VStack(spacing: 0) {
            Text("⚠️")
                .font(.system(size: 36))
                .padding(.bottom, 10)

            Text("Could not load apps")
                .font(.system(size: 14, weight: .bold, design: theme.fontDesign))
                .foregroundStyle(theme.textPrimary)
                .padding(.bottom, 6)

            Text("No credentials found.\nRun the command below in Terminal.")
                .font(.system(size: 11, design: theme.fontDesign))
                .foregroundStyle(theme.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.bottom, 12)

            authCommandSnippet
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(theme.statusRemoved.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(theme.statusRemoved.opacity(0.2), lineWidth: 1)
                )
        )
    }

    // MARK: - $ asc auth login snippet

    private var authCommandSnippet: some View {
        HStack {
            Text("$ asc auth login")
                .font(.system(size: 11, design: .monospaced))
                .foregroundStyle(theme.textMono)

            Spacer()

            Button("Copy") { onCopy?("asc auth login") }
                .font(.system(size: 10, weight: .bold, design: theme.fontDesign))
                .foregroundStyle(theme.accentPrimary)
                .buttonStyle(.plain)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.black.opacity(0.35))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(theme.textMono.opacity(0.15), lineWidth: 1)
                )
        )
    }

    // MARK: - 🔑 Set up credentials row

    private var credentialsRow: some View {
        HStack(spacing: 8) {
            Text("🔑")
                .font(.system(size: 13))
                .padding(6)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(BaseColors.systemBlue.opacity(0.15))
                )

            Text("Set up credentials")
                .font(.system(size: 12, weight: .medium, design: theme.fontDesign))
                .foregroundStyle(theme.textPrimary)

            Spacer()

            Text("Guide ›")
                .font(.system(size: 12, design: theme.fontDesign))
                .foregroundStyle(theme.accentPrimary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(theme.glassBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(theme.glassBorder, lineWidth: 1)
                )
        )
    }
}
