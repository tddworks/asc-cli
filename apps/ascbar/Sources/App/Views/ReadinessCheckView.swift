import SwiftUI
import AppKit
import Domain

/// Screen 6 — pre-flight readiness check with MUST FIX / SHOULD FIX / PASSING sections.
struct ReadinessCheckView: View {
    let version: ASCVersion
    let detailRepository: any VersionDetailRepository
    let onFixLocalizations: () -> Void
    let onBack: () -> Void

    @Environment(\.appTheme) private var theme
    @State private var isLoading = true
    @State private var result: VersionReadinessResult? = nil
    @State private var loadError: String? = nil

    var body: some View {
        VStack(spacing: 0) {
            header
            content
            actionBar
        }
        .task { await loadReadiness() }
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

            Text("Readiness Check")
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

    @ViewBuilder
    private var content: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                if isLoading {
                    loadingView
                } else if let error = loadError {
                    errorView(error)
                } else if let result {
                    resultContent(result)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 4)
        }
    }

    private var loadingView: some View {
        HStack {
            Spacer()
            VStack(spacing: 8) {
                ProgressView()
                    .progressViewStyle(.circular)
                    .scaleEffect(0.8)
                Text("Checking readiness…")
                    .font(.system(size: 12, design: theme.fontDesign))
                    .foregroundStyle(theme.textSecondary)
            }
            Spacer()
        }
        .padding(.vertical, 32)
    }

    private func errorView(_ error: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(BaseColors.systemOrange)
                Text("Failed to load")
                    .font(.system(size: 13, weight: .semibold, design: theme.fontDesign))
                    .foregroundStyle(theme.textPrimary)
            }
            Text(error)
                .font(.system(size: 11, design: .monospaced))
                .foregroundStyle(theme.textSecondary)
                .lineLimit(3)
            Button("Retry") { Task { await loadReadiness() } }
                .buttonStyle(.plain)
                .foregroundStyle(theme.accentPrimary)
                .font(.system(size: 12, weight: .semibold, design: theme.fontDesign))
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(BaseColors.systemOrange.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(BaseColors.systemOrange.opacity(0.25), lineWidth: 1)
                )
        )
    }

    @ViewBuilder
    private func resultContent(_ result: VersionReadinessResult) -> some View {
        readinessBadge(isReady: result.isReadyToSubmit)

        if !result.mustFix.isEmpty {
            checkSection(title: "MUST FIX", items: result.mustFix, color: BaseColors.systemRed)
        }
        if !result.shouldFix.isEmpty {
            checkSection(title: "SHOULD FIX", items: result.shouldFix, color: BaseColors.systemOrange)
        }
        if !result.passing.isEmpty {
            checkSection(title: "PASSING", items: result.passing, color: BaseColors.systemGreen)
        }
    }

    private func readinessBadge(isReady: Bool) -> some View {
        let color = isReady ? BaseColors.systemGreen : BaseColors.systemRed
        return HStack(spacing: 8) {
            Image(systemName: isReady ? "checkmark.circle.fill" : "xmark.circle.fill")
                .font(.system(size: 16))
                .foregroundStyle(color)
            Text(isReady ? "Ready to Submit" : "Not Ready")
                .font(.system(size: 14, weight: .bold, design: theme.fontDesign))
                .foregroundStyle(theme.textPrimary)
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(color.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(color.opacity(0.25), lineWidth: 1)
                )
        )
    }

    private func checkSection(title: String, items: [ReadinessItem], color: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 11, weight: .bold, design: theme.fontDesign))
                .foregroundStyle(color)
                .tracking(0.6)

            VStack(spacing: 0) {
                ForEach(Array(items.enumerated()), id: \.element.id) { idx, item in
                    if idx > 0 {
                        Rectangle().fill(theme.dividerColor).frame(height: 1)
                    }
                    checkItemRow(item: item, sectionColor: color)
                }
            }
            .background(card)
        }
    }

    private func checkItemRow(item: ReadinessItem, sectionColor: Color) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                Image(systemName: sectionIcon(for: sectionColor))
                    .font(.system(size: 13))
                    .foregroundStyle(sectionColor)
                VStack(alignment: .leading, spacing: 2) {
                    Text(item.title)
                        .font(.system(size: 13, weight: .semibold, design: theme.fontDesign))
                        .foregroundStyle(theme.textPrimary)
                    Text(item.description)
                        .font(.system(size: 11, design: theme.fontDesign))
                        .foregroundStyle(theme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer()
            }
            if let action = item.fixAction {
                fixActionButton(action: action)
                    .padding(.leading, 21)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }

    private func sectionIcon(for color: Color) -> String {
        if color == BaseColors.systemGreen  { return "checkmark.circle.fill" }
        if color == BaseColors.systemRed    { return "xmark.circle.fill" }
        return "exclamationmark.circle.fill"
    }

    @ViewBuilder
    private func fixActionButton(action: ReadinessFixAction) -> some View {
        switch action {
        case .copyCommand(let cmd):
            Button {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(cmd, forType: .string)
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "doc.on.doc").font(.system(size: 9, weight: .semibold))
                    Text(cmd)
                        .font(.system(size: 10, design: .monospaced))
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
                .foregroundStyle(theme.accentPrimary)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(
                    RoundedRectangle(cornerRadius: 4)
                        .fill(theme.accentPrimary.opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: 4)
                                .stroke(theme.accentPrimary.opacity(0.2), lineWidth: 1)
                        )
                )
            }
            .buttonStyle(.plain)

        case .navigateToLocalizations:
            Button(action: onFixLocalizations) {
                HStack(spacing: 4) {
                    Image(systemName: "pencil").font(.system(size: 9, weight: .semibold))
                    Text("Fix What's New")
                        .font(.system(size: 10, weight: .semibold, design: theme.fontDesign))
                }
                .foregroundStyle(BaseColors.systemOrange)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(
                    RoundedRectangle(cornerRadius: 4)
                        .fill(BaseColors.systemOrange.opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: 4)
                                .stroke(BaseColors.systemOrange.opacity(0.2), lineWidth: 1)
                        )
                )
            }
            .buttonStyle(.plain)
        }
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

    // MARK: - Helpers

    private var card: some View {
        RoundedRectangle(cornerRadius: theme.cardCornerRadius)
            .fill(theme.glassBackground)
            .overlay(
                RoundedRectangle(cornerRadius: theme.cardCornerRadius)
                    .stroke(theme.glassBorder, lineWidth: 1)
            )
    }

    private func loadReadiness() async {
        isLoading = true
        loadError = nil
        do {
            result = try await detailRepository.fetchReadiness(versionId: version.id)
        } catch {
            loadError = error.localizedDescription
        }
        isLoading = false
    }
}

// MARK: - Previews

#Preview("Readiness — Loading") {
    ReadinessCheckView(
        version: ASCVersion(id: "v1", appId: "app1", versionString: "2.1.0",
                            platform: "MAC_OS", state: "PREPARE_FOR_SUBMISSION"),
        detailRepository: SlowPreviewRepository(),
        onFixLocalizations: {},
        onBack: {}
    )
    .frame(width: 400)
    .appThemeProvider(themeModeId: "dark")
}

#Preview("Readiness — Not Ready") {
    ReadinessCheckView(
        version: ASCVersion(id: "v1", appId: "app1", versionString: "2.1.0",
                            platform: "MAC_OS", state: "PREPARE_FOR_SUBMISSION"),
        detailRepository: PreviewVersionDetailRepository(),
        onFixLocalizations: {},
        onBack: {}
    )
    .frame(width: 400)
    .appThemeProvider(themeModeId: "dark")
}

private struct SlowPreviewRepository: VersionDetailRepository {
    func fetchReadiness(versionId: String) async throws -> VersionReadinessResult {
        try await Task.sleep(for: .seconds(60))
        fatalError("unreachable in preview")
    }
    func fetchLocalizations(versionId: String) async throws -> [LocalizationSummary] { [] }
    func updateWhatsNew(localizationId: String, text: String) async throws {}
}
