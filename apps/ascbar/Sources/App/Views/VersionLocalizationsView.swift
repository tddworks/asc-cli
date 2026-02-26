import SwiftUI
import AppKit
import Domain

// MARK: - Draft Model

/// Editable snapshot of all text fields for one localization.
private struct LocalizationDraft: Equatable {
    var whatsNew: String
    var description: String
    var keywords: String
    var marketingUrl: String
    var supportUrl: String
    var promotionalText: String

    init(from loc: LocalizationSummary) {
        whatsNew        = loc.whatsNew        ?? ""
        description     = loc.description     ?? ""
        keywords        = loc.keywords        ?? ""
        marketingUrl    = loc.marketingUrl    ?? ""
        supportUrl      = loc.supportUrl      ?? ""
        promotionalText = loc.promotionalText ?? ""
    }

    func changedFields(comparedTo loc: LocalizationSummary) -> (
        whatsNew: String?, description: String?, keywords: String?,
        marketingUrl: String?, supportUrl: String?, promotionalText: String?
    ) {
        func diff(_ draft: String, _ original: String?) -> String? {
            draft != (original ?? "") ? draft : nil
        }
        return (
            diff(whatsNew,        loc.whatsNew),
            diff(description,     loc.description),
            diff(keywords,        loc.keywords),
            diff(marketingUrl,    loc.marketingUrl),
            diff(supportUrl,      loc.supportUrl),
            diff(promotionalText, loc.promotionalText)
        )
    }
}

// MARK: - View

/// Screen 7 — locale tab picker + focused What's New editor.
/// Mental model: "I'm writing release notes — pick a language, fill in What's New, save."
struct VersionLocalizationsView: View {
    let version: ASCVersion
    let detailRepository: any VersionDetailRepository
    let onBack: () -> Void

    @Environment(\.appTheme) private var theme
    @State private var localizations: [LocalizationSummary] = []
    @State private var isLoading = true
    @State private var loadError: String? = nil

    @State private var selectedId: String = ""
    // Non-optional @State draft → $draft.field gives @Sendable-safe bindings
    @State private var draft = LocalizationDraft(from: .empty)
    @State private var savedDraft = LocalizationDraft(from: .empty)  // for change detection

    @State private var isSaving = false
    @State private var saveError: String? = nil
    @State private var copiedCmd = false

    private var selectedLocale: LocalizationSummary? {
        localizations.first(where: { $0.id == selectedId }) ?? localizations.first
    }

    private var hasChanges: Bool { draft != savedDraft }

    var body: some View {
        VStack(spacing: 0) {
            header
            if isLoading {
                loadingView
            } else if let error = loadError {
                errorView(error)
            } else if localizations.isEmpty {
                emptyView
            } else {
                localeTabs
                editorScroll
                if let loc = selectedLocale {
                    actionBar(for: loc)
                }
            }
        }
        .task { await loadLocalizations() }
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            Button(action: onBack) {
                HStack(spacing: 4) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 12, weight: .semibold))
                    Text(version.versionString)
                        .font(.system(size: 13, weight: .semibold, design: theme.fontDesign))
                }
                .foregroundStyle(theme.accentPrimary)
            }
            .buttonStyle(.plain)

            Spacer()

            Text("Localizations")
                .font(.system(size: 14, weight: .bold, design: theme.fontDesign))
                .foregroundStyle(theme.textPrimary)

            Spacer()

            Color.clear.frame(width: 80, height: 1)
        }
        .padding(.horizontal, 16)
        .padding(.top, 14)
        .padding(.bottom, 10)
    }

    // MARK: - Locale Tabs

    private var localeTabs: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(localizations) { loc in
                    Button {
                        switchLocale(to: loc)
                    } label: {
                        HStack(spacing: 4) {
                            Text(loc.locale)
                                .font(.system(size: 12, weight: .semibold, design: theme.fontDesign))
                            if loc.isPrimary {
                                Text("★")
                                    .font(.system(size: 9, weight: .bold))
                                    .foregroundStyle(BaseColors.systemPurple.opacity(0.8))
                            }
                        }
                        .foregroundStyle(loc.id == selectedId ? theme.textPrimary : theme.textSecondary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 5)
                        .background(
                            Capsule()
                                .fill(loc.id == selectedId
                                      ? BaseColors.systemPurple.opacity(0.15)
                                      : theme.glassBackground)
                                .overlay(
                                    Capsule()
                                        .stroke(loc.id == selectedId
                                                ? BaseColors.systemPurple.opacity(0.35)
                                                : theme.glassBorder, lineWidth: 1)
                                )
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
    }

    // MARK: - Editor scroll

    private var editorScroll: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                whatsNewField
                otherFields
                if let loc = selectedLocale {
                    cliCommandPreview(for: loc)
                }
                if let err = saveError {
                    saveErrorBanner(err)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 10)
            .padding(.bottom, 4)
        }
        .frame(maxHeight: 340)
    }

    // MARK: - What's New (primary field)

    private var whatsNewField: some View {
        let isEmpty = draft.whatsNew.isEmpty
        return VStack(alignment: .leading, spacing: 5) {
            HStack {
                Text("WHAT'S NEW")
                    .font(.system(size: 10, weight: .bold, design: theme.fontDesign))
                    .foregroundStyle(isEmpty ? BaseColors.systemOrange : theme.textTertiary)
                    .tracking(0.6)
                if isEmpty {
                    Text("— not set")
                        .font(.system(size: 10, design: theme.fontDesign))
                        .foregroundStyle(BaseColors.systemOrange.opacity(0.7))
                }
            }

            // $draft.whatsNew is a @State-backed Binding — no Sendable issues
            TextEditor(text: $draft.whatsNew)
                .font(.system(size: 13, design: theme.fontDesign))
                .foregroundStyle(theme.textPrimary)
                .scrollContentBackground(.hidden)
                .frame(height: 88)
                .padding(8)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(isEmpty
                              ? BaseColors.systemOrange.opacity(0.05)
                              : theme.codeBackground)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(isEmpty
                                        ? BaseColors.systemOrange.opacity(0.35)
                                        : theme.glassBorder, lineWidth: 1)
                        )
                )

            Text("Shown to users in the App Store Updates tab")
                .font(.system(size: 10, design: theme.fontDesign))
                .foregroundStyle(theme.textTertiary)
        }
    }

    // MARK: - Other Fields (always visible, flat)

    private var otherFields: some View {
        let setCount = [draft.description, draft.keywords, draft.marketingUrl,
                        draft.supportUrl, draft.promotionalText]
            .filter { !$0.isEmpty }.count

        return VStack(alignment: .leading, spacing: 10) {
            // Section header row
            HStack(spacing: 8) {
                Text("🔤").font(.system(size: 13))
                Text("Description · Keywords · URLs")
                    .font(.system(size: 12, weight: .semibold, design: theme.fontDesign))
                    .foregroundStyle(theme.textSecondary)
                Spacer()
                Text("\(setCount)/5 set")
                    .font(.system(size: 9, weight: .bold, design: theme.fontDesign))
                    .foregroundStyle(setCount > 0 ? BaseColors.systemGreen : theme.textTertiary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(
                        RoundedRectangle(cornerRadius: 4)
                            .fill((setCount > 0 ? BaseColors.systemGreen : theme.textTertiary).opacity(0.15))
                    )
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 9)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(theme.glassBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(theme.glassBorder, lineWidth: 1)
                    )
            )
            inlineField(label: "Description", text: $draft.description,
                        multiline: true, hint: "Min 10 chars",
                        validationError: descriptionError)
            inlineField(label: "Keywords", text: $draft.keywords,
                        multiline: false, hint: "Comma-separated")
            inlineField(label: "Marketing URL", text: $draft.marketingUrl,
                        multiline: false, hint: "https://",
                        validationError: urlError(draft.marketingUrl))
            inlineField(label: "Support URL", text: $draft.supportUrl,
                        multiline: false, hint: "https://",
                        validationError: urlError(draft.supportUrl))
            inlineField(label: "Promotional Text", text: $draft.promotionalText,
                        multiline: true)
        }
    }

    // Binding<String> parameter — Sendable by construction, no closure forwarding
    private func inlineField(
        label: String,
        text: Binding<String>,
        multiline: Bool,
        hint: String? = nil,
        validationError: String? = nil
    ) -> some View {
        let hasError = validationError != nil
        return VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.system(size: 10, weight: .semibold, design: theme.fontDesign))
                .foregroundStyle(hasError ? BaseColors.systemRed : theme.textTertiary)
                .tracking(0.3)

            if multiline {
                TextEditor(text: text)
                    .font(.system(size: 12, design: theme.fontDesign))
                    .foregroundStyle(theme.textPrimary)
                    .scrollContentBackground(.hidden)
                    .frame(height: 54)
                    .padding(4)
                    .background(fieldBackground(hasError: hasError))
            } else {
                TextField("", text: text)
                    .font(.system(size: 12, design: theme.fontDesign))
                    .foregroundStyle(theme.textPrimary)
                    .textFieldStyle(.plain)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 5)
                    .background(fieldBackground(hasError: hasError))
            }

            if let err = validationError {
                Text(err).font(.system(size: 9)).foregroundStyle(BaseColors.systemRed)
            } else if let hint {
                Text(hint).font(.system(size: 9)).foregroundStyle(theme.textTertiary)
            }
        }
    }

    private func fieldBackground(hasError: Bool) -> some View {
        RoundedRectangle(cornerRadius: 6)
            .fill(hasError ? BaseColors.systemRed.opacity(0.07) : theme.codeBackground)
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(hasError ? BaseColors.systemRed.opacity(0.4) : theme.glassBorder, lineWidth: 1)
            )
    }

    // MARK: - Validation

    private var descriptionError: String? {
        let v = draft.description
        if !v.isEmpty && v.count < 10 { return "At least 10 characters required" }
        return nil
    }

    private func urlError(_ value: String) -> String? {
        if !value.isEmpty && !value.hasPrefix("https://") && !value.hasPrefix("http://") {
            return "Must start with https://"
        }
        return nil
    }

    private var hasValidationErrors: Bool {
        descriptionError != nil
            || urlError(draft.marketingUrl) != nil
            || urlError(draft.supportUrl) != nil
    }

    // MARK: - CLI Command Preview

    private func cliCommandPreview(for loc: LocalizationSummary) -> some View {
        let cmd = buildCLICommand(draft: draft, loc: loc)
        let text = cmd ?? "asc version-localizations update --localization-id \(loc.id)"
        let hasCmd = cmd != nil

        return VStack(alignment: .leading, spacing: 5) {
            Text("CLI COMMAND")
                .font(.system(size: 10, weight: .bold, design: theme.fontDesign))
                .foregroundStyle(theme.textTertiary)
                .tracking(0.6)

            HStack(alignment: .top, spacing: 8) {
                ScrollView(.horizontal, showsIndicators: false) {
                    Text(text)
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundStyle(hasCmd ? theme.textMono : theme.textTertiary)
                        .fixedSize(horizontal: true, vertical: false)
                }

                Button {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(text, forType: .string)
                    withAnimation { copiedCmd = true }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        withAnimation { copiedCmd = false }
                    }
                } label: {
                    Text(copiedCmd ? "✓" : "Copy")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(copiedCmd ? theme.statusLive : theme.accentPrimary)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 2)
                        .background(
                            RoundedRectangle(cornerRadius: 4)
                                .fill((copiedCmd ? theme.statusLive : theme.accentPrimary).opacity(0.12))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 4)
                                        .stroke((copiedCmd ? theme.statusLive : theme.accentPrimary).opacity(0.25), lineWidth: 1)
                                )
                        )
                }
                .buttonStyle(.plain)
                .animation(.easeInOut(duration: 0.15), value: copiedCmd)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(theme.codeBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(hasCmd
                                    ? theme.textMono.opacity(0.2)
                                    : theme.glassBorder, lineWidth: 1)
                    )
            )
        }
    }

    // MARK: - Save Error Banner

    private func saveErrorBanner(_ error: String) -> some View {
        HStack(alignment: .top, spacing: 6) {
            Image(systemName: "exclamationmark.circle.fill")
                .font(.system(size: 11))
                .foregroundStyle(BaseColors.systemRed)
            Text("Failed: \(error)")
                .font(.system(size: 11, design: theme.fontDesign))
                .foregroundStyle(BaseColors.systemRed)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(BaseColors.systemRed.opacity(0.08))
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(BaseColors.systemRed.opacity(0.2), lineWidth: 1))
        )
    }

    // MARK: - Action Bar

    private func actionBar(for loc: LocalizationSummary) -> some View {
        let changed = draft.changedFields(comparedTo: loc)
        let hasErrors = hasValidationErrors
        let cmd = buildCLICommand(draft: draft, loc: loc)

        return HStack(spacing: 8) {
            if hasChanges {
                Button {
                    switchLocale(to: loc)
                } label: {
                    Text("Cancel")
                        .font(.system(size: 12, weight: .semibold, design: theme.fontDesign))
                        .foregroundStyle(theme.textSecondary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Capsule().fill(theme.glassBackground)
                            .overlay(Capsule().stroke(theme.glassBorder, lineWidth: 1)))
                }
                .buttonStyle(.plain)
            }

            Spacer()

            if let cmd {
                Button {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(cmd, forType: .string)
                    withAnimation { copiedCmd = true }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        withAnimation { copiedCmd = false }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: copiedCmd ? "checkmark" : "doc.on.doc")
                            .font(.system(size: 9, weight: .semibold))
                        Text(copiedCmd ? "Copied!" : "Copy Cmd")
                            .font(.system(size: 11, weight: .semibold, design: theme.fontDesign))
                    }
                    .foregroundStyle(copiedCmd ? theme.statusLive : theme.accentPrimary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill((copiedCmd ? theme.statusLive : theme.accentPrimary).opacity(0.1))
                            .overlay(Capsule().stroke((copiedCmd ? theme.statusLive : theme.accentPrimary).opacity(0.25), lineWidth: 1))
                    )
                }
                .buttonStyle(.plain)
                .animation(.easeInOut(duration: 0.15), value: copiedCmd)
            }

            if isSaving {
                ProgressView().progressViewStyle(.circular).scaleEffect(0.75)
            } else {
                let locId = loc.id
                let snapshotDraft = draft
                Button {
                    Task { await saveDraft(snapshotDraft, loc: loc, localizationId: locId) }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark").font(.system(size: 9, weight: .bold))
                        Text("Save")
                            .font(.system(size: 12, weight: .bold, design: theme.fontDesign))
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(hasErrors || !hasChanges
                                  ? Color.gray.opacity(0.3)
                                  : BaseColors.systemPurple)
                    )
                }
                .buttonStyle(.plain)
                .disabled(hasErrors || !hasChanges)
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 10)
        .padding(.bottom, 14)
    }

    // MARK: - State transitions

    private func switchLocale(to loc: LocalizationSummary) {
        withAnimation(.easeOut(duration: 0.15)) {
            selectedId = loc.id
            let fresh = LocalizationDraft(from: loc)
            draft = fresh
            savedDraft = fresh
            saveError = nil
            copiedCmd = false
        }
    }

    // MARK: - Loading / empty / error states

    private var loadingView: some View {
        HStack {
            Spacer()
            VStack(spacing: 8) {
                ProgressView().progressViewStyle(.circular).scaleEffect(0.8)
                Text("Loading localizations…")
                    .font(.system(size: 12, design: theme.fontDesign))
                    .foregroundStyle(theme.textSecondary)
            }
            Spacer()
        }
        .padding(.vertical, 48)
    }

    private func errorView(_ error: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: "exclamationmark.triangle.fill").foregroundStyle(BaseColors.systemOrange)
                Text("Failed to load")
                    .font(.system(size: 13, weight: .semibold, design: theme.fontDesign))
                    .foregroundStyle(theme.textPrimary)
            }
            Text(error)
                .font(.system(size: 11, design: .monospaced))
                .foregroundStyle(theme.textSecondary)
                .lineLimit(3)
            Button("Retry") { Task { await loadLocalizations() } }
                .buttonStyle(.plain)
                .foregroundStyle(theme.accentPrimary)
                .font(.system(size: 12, weight: .semibold, design: theme.fontDesign))
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(BaseColors.systemOrange.opacity(0.1))
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(BaseColors.systemOrange.opacity(0.25), lineWidth: 1))
        )
        .padding(.horizontal, 16)
        .padding(.vertical, 24)
    }

    private var emptyView: some View {
        Text("No localizations found")
            .font(.system(size: 12))
            .foregroundStyle(theme.textTertiary)
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.vertical, 48)
    }

    // MARK: - CLI Command

    private func buildCLICommand(draft: LocalizationDraft, loc: LocalizationSummary) -> String? {
        let changed = draft.changedFields(comparedTo: loc)
        var parts: [String] = ["asc version-localizations update --localization-id \(loc.id)"]
        if let v = changed.whatsNew        { parts.append("--whats-new \(shellQuote(v))") }
        if let v = changed.description     { parts.append("--description \(shellQuote(v))") }
        if let v = changed.keywords        { parts.append("--keywords \(shellQuote(v))") }
        if let v = changed.marketingUrl    { parts.append("--marketing-url \(shellQuote(v))") }
        if let v = changed.supportUrl      { parts.append("--support-url \(shellQuote(v))") }
        if let v = changed.promotionalText { parts.append("--promotional-text \(shellQuote(v))") }
        guard parts.count > 1 else { return nil }
        return parts.joined(separator: " \\\n  ")
    }

    private func shellQuote(_ s: String) -> String {
        "'\(s.replacingOccurrences(of: "'", with: "'\\''"))'"
    }

    // MARK: - Network

    private func loadLocalizations() async {
        isLoading = true
        loadError = nil
        do {
            localizations = try await detailRepository.fetchLocalizations(versionId: version.id)
            if let first = localizations.first {
                selectedId = first.id
                let fresh = LocalizationDraft(from: first)
                draft = fresh
                savedDraft = fresh
            }
        } catch {
            loadError = error.localizedDescription
        }
        isLoading = false
    }

    private func saveDraft(
        _ snapshotDraft: LocalizationDraft,
        loc: LocalizationSummary,
        localizationId: String
    ) async {
        isSaving = true
        saveError = nil
        let changed = snapshotDraft.changedFields(comparedTo: loc)
        guard changed.whatsNew != nil || changed.description != nil || changed.keywords != nil
                || changed.marketingUrl != nil || changed.supportUrl != nil || changed.promotionalText != nil
        else {
            savedDraft = snapshotDraft
            isSaving = false
            return
        }
        do {
            try await detailRepository.updateLocalization(
                localizationId: localizationId,
                whatsNew: changed.whatsNew,
                description: changed.description,
                keywords: changed.keywords,
                marketingUrl: changed.marketingUrl,
                supportUrl: changed.supportUrl,
                promotionalText: changed.promotionalText
            )
            // Update local cache without a network round-trip
            if let idx = localizations.firstIndex(where: { $0.id == localizationId }) {
                let orig = localizations[idx]
                func apply(_ c: String?, _ o: String?) -> String? {
                    guard let c else { return o }
                    return c.isEmpty ? nil : c
                }
                localizations[idx] = LocalizationSummary(
                    id: orig.id, locale: orig.locale, isPrimary: orig.isPrimary,
                    whatsNew: apply(changed.whatsNew, orig.whatsNew),
                    description: apply(changed.description, orig.description),
                    keywords: apply(changed.keywords, orig.keywords),
                    marketingUrl: apply(changed.marketingUrl, orig.marketingUrl),
                    supportUrl: apply(changed.supportUrl, orig.supportUrl),
                    promotionalText: apply(changed.promotionalText, orig.promotionalText)
                )
            }
            savedDraft = snapshotDraft
        } catch {
            saveError = error.localizedDescription
        }
        isSaving = false
    }
}

// MARK: - LocalizationSummary convenience

private extension LocalizationSummary {
    static var empty: LocalizationSummary {
        LocalizationSummary(id: "", locale: "", isPrimary: false)
    }
}

// MARK: - Previews

#Preview("Localizations — Loaded") {
    VersionLocalizationsView(
        version: ASCVersion(id: "v1", appId: "app1", versionString: "2.1.0",
                            platform: "MAC_OS", state: "PREPARE_FOR_SUBMISSION"),
        detailRepository: PreviewVersionDetailRepository(),
        onBack: {}
    )
    .frame(width: 400)
    .appThemeProvider(themeModeId: "dark")
}

#Preview("Localizations — Light") {
    VersionLocalizationsView(
        version: ASCVersion(id: "v1", appId: "app1", versionString: "2.1.0",
                            platform: "MAC_OS", state: "PREPARE_FOR_SUBMISSION"),
        detailRepository: PreviewVersionDetailRepository(),
        onBack: {}
    )
    .frame(width: 400)
    .appThemeProvider(themeModeId: "light")
}
