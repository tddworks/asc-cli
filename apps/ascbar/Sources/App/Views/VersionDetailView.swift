import SwiftUI
import Domain

/// Screen 5 — version detail: state, build info, and navigation to readiness/localizations.
struct VersionDetailView: View {
    let version: ASCVersion
    let detailRepository: any VersionDetailRepository
    let onOpenReadiness: () -> Void
    let onOpenLocalizations: () -> Void
    let onBack: () -> Void

    @Environment(\.appTheme) private var theme

    var body: some View {
        VStack(spacing: 0) {
            header
            content
            Spacer(minLength: 0)
            actionBar
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            Button(action: onBack) {
                HStack(spacing: 4) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 12, weight: .semibold))
                    Text("Back")
                        .font(.system(size: 13, weight: .semibold, design: theme.fontDesign))
                }
                .foregroundStyle(theme.accentPrimary)
            }
            .buttonStyle(.plain)

            Spacer()

            Text("\(version.versionString) · \(version.platformDisplayName)")
                .font(.system(size: 14, weight: .bold, design: theme.fontDesign))
                .foregroundStyle(theme.textPrimary)

            Spacer()

            Color.clear.frame(width: 60, height: 1)
        }
        .padding(.horizontal, 16)
        .padding(.top, 14)
        .padding(.bottom, 10)
    }

    // MARK: - Content

    private var content: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Version info card
            VStack(spacing: 0) {
                infoRow(
                    label: "State",
                    value: version.stateDisplayName,
                    valueColor: theme.statusColor(for: version.appStatus)
                )
                rowDivider
                infoRow(
                    label: "Build",
                    value: version.buildId ?? "Not attached",
                    valueColor: version.buildId != nil ? theme.textPrimary : theme.textTertiary
                )
            }
            .background(card)
            .padding(.horizontal, 16)

            // Navigation rows
            VStack(spacing: 0) {
                navRow(
                    icon: "checklist",
                    iconColor: BaseColors.systemGreen,
                    title: "Readiness Check",
                    subtitle: "Pre-flight submission check",
                    action: onOpenReadiness
                )
                rowDivider
                navRow(
                    icon: "globe",
                    iconColor: BaseColors.systemBlue,
                    title: "Localizations",
                    subtitle: "View and edit What's New text",
                    action: onOpenLocalizations
                )
            }
            .background(card)
            .padding(.horizontal, 16)
        }
        .padding(.top, 4)
    }

    // MARK: - Helpers

    private func infoRow(label: String, value: String, valueColor: Color) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 13, design: theme.fontDesign))
                .foregroundStyle(theme.textSecondary)
            Spacer()
            Text(value)
                .font(.system(size: 13, weight: .semibold, design: theme.fontDesign))
                .foregroundStyle(valueColor)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }

    private func navRow(
        icon: String,
        iconColor: Color,
        title: String,
        subtitle: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(iconColor)
                    .frame(width: 28, height: 28)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(iconColor.opacity(0.15))
                    )

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 13, weight: .semibold, design: theme.fontDesign))
                        .foregroundStyle(theme.textPrimary)
                    Text(subtitle)
                        .font(.system(size: 11, design: theme.fontDesign))
                        .foregroundStyle(theme.textSecondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(theme.textTertiary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var rowDivider: some View {
        Rectangle()
            .fill(theme.dividerColor)
            .frame(height: 1)
    }

    private var card: some View {
        RoundedRectangle(cornerRadius: theme.cardCornerRadius)
            .fill(theme.glassBackground)
            .overlay(
                RoundedRectangle(cornerRadius: theme.cardCornerRadius)
                    .stroke(theme.glassBorder, lineWidth: 1)
            )
    }

    // MARK: - Action Bar

    private var actionBar: some View {
        HStack {
            Spacer()
            Button(action: onBack) {
                HStack(spacing: 5) {
                    Image(systemName: "xmark").font(.system(size: 10, weight: .bold))
                    Text("Close").font(.system(size: 12, weight: .bold, design: theme.fontDesign))
                }
                .foregroundStyle(theme.textSecondary)
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(
                    Capsule()
                        .fill(theme.glassBackground)
                        .overlay(Capsule().stroke(theme.glassBorder, lineWidth: 1))
                )
            }
            .buttonStyle(.plain)
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.top, 10)
        .padding(.bottom, 14)
    }
}

// MARK: - Preview

#Preview("Version Detail") {
    VersionDetailView(
        version: ASCVersion(id: "v1", appId: "app1", versionString: "2.1.0", platform: "MAC_OS",
                            state: "PREPARE_FOR_SUBMISSION"),
        detailRepository: PreviewVersionDetailRepository(),
        onOpenReadiness: {},
        onOpenLocalizations: {},
        onBack: {}
    )
    .frame(width: 400)
    .appThemeProvider(themeModeId: "dark")
}

// MARK: - Preview Helpers

struct PreviewVersionDetailRepository: VersionDetailRepository {
    func fetchReadiness(versionId: String) async throws -> VersionReadinessResult {
        try await Task.sleep(for: .milliseconds(800))
        return VersionReadinessResult(
            versionId: versionId,
            versionString: "2.1.0",
            isReadyToSubmit: false,
            buildLabel: nil,
            mustFix: [
                ReadinessItem(id: "build", title: "Build Attached",
                              description: "No build attached",
                              fixAction: .copyCommand("asc builds list --app-id app1"))
            ],
            shouldFix: [
                ReadinessItem(id: "whatsNew", title: "What's New Text",
                              description: "Missing in: en-US, zh-Hans",
                              fixAction: .navigateToLocalizations)
            ],
            passing: [
                ReadinessItem(id: "state", title: "Version State",
                              description: "Version is in an editable state"),
                ReadinessItem(id: "pricing", title: "Pricing",
                              description: "Price schedule configured"),
                ReadinessItem(id: "reviewContact", title: "Review Contact",
                              description: "Review contact is set")
            ]
        )
    }

    func fetchLocalizations(versionId: String) async throws -> [LocalizationSummary] {
        try await Task.sleep(for: .milliseconds(600))
        return [
            LocalizationSummary(id: "l1", locale: "en-US", whatsNew: "Bug fixes and improvements.", isPrimary: true),
            LocalizationSummary(id: "l2", locale: "zh-Hans", whatsNew: nil, isPrimary: false),
            LocalizationSummary(id: "l3", locale: "ja", whatsNew: "バグ修正と改善。", isPrimary: false),
        ]
    }

    func updateWhatsNew(localizationId: String, text: String) async throws {
        try await Task.sleep(for: .seconds(1))
    }
}
