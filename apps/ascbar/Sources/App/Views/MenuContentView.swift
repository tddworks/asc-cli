import SwiftUI
import Shimmer
import Domain

/// Main menu bar popup — three states matching row-1-core-states.html exactly.
///
/// Layout fix: content is a plain VStack; background (solid colour + orbs) is applied
/// via `.background {}` so `GeometryReader` never participates in the parent layout pass.
/// This eliminates the "Update Constraints in Window" constraint loop.
struct MenuContentView: View {
    let portfolio: AppPortfolio

    @Environment(\.appTheme) private var theme
    @State private var showSettings = false
    @State private var animateIn = false
    @State private var lastCopiedCommand: String? = nil
    @State private var copiedConfirmed = false

    // MARK: - State helpers (read domain directly)

    private var isLoading: Bool { portfolio.isSyncing && portfolio.apps.isEmpty }
    private var isError: Bool   { portfolio.lastError != nil && portfolio.apps.isEmpty }

    // MARK: - Root

    var body: some View {
        Group {
            if showSettings {
                SettingsContentView(showSettings: $showSettings, monitor: portfolio)
            } else {
                mainContent
            }
        }
        .frame(width: 400)
        .background { popoverBackground }
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .task {
            withAnimation(.easeOut(duration: 0.4)) { animateIn = true }
            await portfolio.refresh()
        }
    }

    // MARK: - Popover background (solid #1e1e20 + two orbs)
    // GeometryReader lives here — inside .background{} it cannot affect parent layout.

    private var popoverBackground: some View {
        GeometryReader { proxy in
            // --bg-base: #1e1e20
            Color(red: 0.118, green: 0.118, blue: 0.125)

            // Orb 1 — purple top-left  (--orb1: rgba(120,60,220,.35))
            // CSS: top:-80px; left:-60px; width:220px → centre at (50, 30)
            Circle()
                .fill(RadialGradient(
                    colors: [Color(red: 120/255, green: 60/255, blue: 220/255).opacity(0.35), .clear],
                    center: .center, startRadius: 0, endRadius: 110))
                .frame(width: 220, height: 220)
                .position(x: 50, y: 30)

            // Orb 2 — pink bottom-right  (--orb2: rgba(220,60,120,.28))
            // CSS: bottom:-60px; right:-40px; width:180px → centre at (w-50, h-30)
            Circle()
                .fill(RadialGradient(
                    colors: [Color(red: 220/255, green: 60/255, blue: 120/255).opacity(0.28), .clear],
                    center: .center, startRadius: 0, endRadius: 90))
                .frame(width: 180, height: 180)
                .position(x: proxy.size.width - 50, y: proxy.size.height - 30)
        }
    }

    // MARK: - Main content

    private var mainContent: some View {
        VStack(spacing: 0) {
            header
                .padding(.horizontal, 16)
                .padding(.top, 14)
                .padding(.bottom, 10)
                .overlay(alignment: .bottom) { divider }

            if !portfolio.apps.isEmpty {
                appPillsRow
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .overlay(alignment: .bottom) { divider }
            }

            contentSection

            if let cmd = lastCopiedCommand {
                codeSnippetBar(cmd)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 8)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }

            actionBar
                .padding(.horizontal, 16)
                .padding(.top, 2)
                .padding(.bottom, 14)
                .overlay(alignment: .top) { divider }
        }
        .animation(.easeOut(duration: 0.2), value: lastCopiedCommand)
    }

    private var divider: some View {
        // rgba(255,255,255,.06)
        Rectangle().fill(Color.white.opacity(0.06)).frame(height: 1)
    }

    // MARK: - Header  (matches .pop-header)

    private var header: some View {
        HStack(spacing: 12) {
            // .logo-circle — linear-gradient(135deg, #7b5af5, #c74af7) + shadow
            ZStack {
                Circle()
                    .fill(theme.accentGradient)
                    .frame(width: 36, height: 36)
                    .shadow(color: BaseColors.brandPurple.opacity(0.45), radius: 8, y: 2)
                Image(systemName: "square.grid.2x2.fill")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.white)
            }

            // .pop-title
            VStack(alignment: .leading, spacing: 1) {
                Text("ASCBar")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(theme.textPrimary)
                Text("> app monitor")
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundStyle(theme.textSecondary)
            }

            Spacer()

            // .status-pill
            statusPill
        }
        .opacity(animateIn ? 1 : 0)
        .offset(y: animateIn ? 0 : -6)
        .animation(.easeOut(duration: 0.4), value: animateIn)
    }

    // MARK: - Status pill

    private var statusPill: some View {
        HStack(spacing: 5) {
            statusDot
            Text(statusText)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(theme.textPrimary)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        // .status-pill: background bg-card, border --border, radius 20px
        .background(
            Capsule()
                .fill(theme.glassBackground)
                .overlay(Capsule().stroke(theme.glassBorder, lineWidth: 1))
        )
    }

    @ViewBuilder
    private var statusDot: some View {
        if portfolio.isSyncing {
            PulsingDot(color: theme.accentPrimary)     // .dot.pulse → --accent
        } else if portfolio.lastError != nil {
            Circle().fill(theme.statusRemoved)          // .dot.red  → --red
                .frame(width: 7, height: 7)
                .shadow(color: theme.statusRemoved.opacity(0.8), radius: 3)
        } else {
            Circle().fill(theme.statusLive)             // .dot.green → --green
                .frame(width: 7, height: 7)
                .shadow(color: theme.statusLive.opacity(0.8), radius: 3)
        }
    }

    private var statusText: String {
        if portfolio.isSyncing    { return "Syncing…" }
        if portfolio.lastError != nil { return "Error" }
        return "Ready"
    }

    // MARK: - App pills row  (matches .pills-row / .app-pill)

    private var appPillsRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(portfolio.apps) { app in
                    AppPillView(
                        app: app,
                        isSelected: portfolio.selectedAppId == app.id,
                        statusColor: app.id == portfolio.selectedAppId
                            ? theme.statusColor(for: portfolio.overallStatus)
                            : theme.textTertiary,
                        onTap: { portfolio.selectApp(app.id) }
                    )
                }
            }
        }
        .opacity(animateIn ? 1 : 0)
        .animation(.easeOut(duration: 0.4).delay(0.05), value: animateIn)
    }

    // MARK: - Content section (state switch)

    @ViewBuilder
    private var contentSection: some View {
        if isLoading {
            shimmerGrid
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 8)
        } else if isError {
            ErrorStateView { cmd in handleCopy(cmd) }
        } else {
            loadedContent
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 8)
        }
    }

    // MARK: - Loaded content  (matches .app-meta-header + .version-grid)

    private var loadedContent: some View {
        VStack(alignment: .leading, spacing: 8) {
            // .app-meta-header
            if let app = portfolio.selectedApp {
                VStack(alignment: .leading, spacing: 1) {
                    Text(app.displayName)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(theme.textPrimary)
                    Text(metaLine(for: app))
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundStyle(theme.textTertiary)
                }
            }

            if portfolio.isSyncing {
                shimmerGrid
            } else if portfolio.selectedVersions.isEmpty {
                Text("No versions found")
                    .font(.system(size: 12))
                    .foregroundStyle(theme.textTertiary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 24)
            } else {
                // .version-grid — grid-template-columns: 1fr 1fr; gap: 8px
                LazyVGrid(
                    columns: [GridItem(.flexible(), spacing: 8), GridItem(.flexible(), spacing: 8)],
                    spacing: 8
                ) {
                    ForEach(portfolio.selectedVersions.prefix(6)) { version in
                        VersionCardView(version: version) { cmd in handleCopy(cmd) }
                    }
                }
                .opacity(animateIn ? 1 : 0)
                .animation(.easeOut(duration: 0.4).delay(0.1), value: animateIn)
            }
        }
    }

    /// "com.example.ascbar · macOS" — suffix only when all versions share one platform.
    private func metaLine(for app: ASCApp) -> String {
        let platforms = Set(portfolio.selectedVersions.map(\.platform))
        if platforms.count == 1, let display = portfolio.selectedVersions.first?.platformDisplayName {
            return "\(app.bundleId) · \(display)"
        }
        return app.bundleId
    }

    // MARK: - Shimmer skeleton grid  (matches .skeleton cards)

    private var shimmerGrid: some View {
        LazyVGrid(
            columns: [GridItem(.flexible(), spacing: 8), GridItem(.flexible(), spacing: 8)],
            spacing: 8
        ) {
            ForEach(0..<4, id: \.self) { _ in skeletonCard }
        }
    }

    private var skeletonCard: some View {
        // Card bg: rgba(255,255,255,.04) — matches .version-card bg in HTML skeleton
        VStack(alignment: .leading, spacing: 6) {
            shimmerBar(width: 40, height: 9)     // platform badge
            shimmerBar(width: 56, height: 22)    // version number
            shimmerBar(width: 88, height: 11)    // state label
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.white.opacity(0.04))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.white.opacity(0.07), lineWidth: 1)
                )
        )
    }

    /// Shimmer bar — two-layer trick:
    ///   • Bottom: solid `white(.18)` fill → always visible (never disappears at trough)
    ///   • Top:    `.shimmering()` with a `clear→white→clear` mask → traveling bright sweep
    /// Effective opacity: trough ≈ 0.18 (light gray), peak ≈ 0.18+boost (bright highlight).
    private func shimmerBar(width: CGFloat, height: CGFloat) -> some View {
        ZStack {
            // Always-on base — the "skeleton" you always see
            RoundedRectangle(cornerRadius: height / 2)
                .fill(Color.white.opacity(0.18))

            // Traveling highlight — adds brightness on top of the base
            RoundedRectangle(cornerRadius: height / 2)
                .fill(Color.white.opacity(0.18))
                .shimmering(
                    animation: .easeInOut(duration: 1.6).repeatForever(autoreverses: false),
                    gradient: Gradient(colors: [
                        Color.clear,
                        Color.white.opacity(0.45),
                        Color.clear,
                    ])
                )
        }
        .frame(width: width, height: height)
    }

    // MARK: - Code snippet toast

    private func codeSnippetBar(_ command: String) -> some View {
        // Matches .code-snippet: bg rgba(0,0,0,.35) border rgba(100,210,255,.15)
        HStack(spacing: 8) {
            Text(command)
                .font(.system(size: 11, design: .monospaced))
                .foregroundStyle(theme.textMono)
                .lineLimit(1)
                .truncationMode(.middle)

            Spacer(minLength: 4)

            Button {
                copyToClipboard(command)
                withAnimation { copiedConfirmed = true }
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    withAnimation { copiedConfirmed = false; lastCopiedCommand = nil }
                }
            } label: {
                // .copy-btn
                Text(copiedConfirmed ? "✓ Copied!" : "Copy")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(copiedConfirmed ? theme.statusLive : theme.accentPrimary)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 2)
                    .background(
                        RoundedRectangle(cornerRadius: 4)
                            .fill((copiedConfirmed ? theme.statusLive : theme.accentPrimary).opacity(0.12))
                            .overlay(
                                RoundedRectangle(cornerRadius: 4)
                                    .stroke((copiedConfirmed ? theme.statusLive : theme.accentPrimary).opacity(0.25), lineWidth: 1)
                            )
                    )
            }
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

    // MARK: - Action bar (state-aware — matches .action-bar)

    @ViewBuilder
    private var actionBar: some View {
        if isLoading {
            loadingActionBar
        } else if isError {
            errorActionBar
        } else {
            loadedActionBar
        }
    }

    /// State 1 — disabled while initial fetch in progress.
    private var loadingActionBar: some View {
        HStack(spacing: 8) {
            appsButton.opacity(0.5).allowsHitTesting(false)
            ghostPill(label: "Syncing", icon: "arrow.triangle.2.circlepath").opacity(0.5)
            Spacer()
            circleIconButton(symbol: "gearshape.fill", help: "Settings") { showSettings = true }
                .opacity(0.4).allowsHitTesting(false)
            circleIconButton(symbol: "xmark", help: "Quit ASCBar") { NSApplication.shared.terminate(nil) }
                .opacity(0.4).allowsHitTesting(false)
        }
    }

    /// State 3 — Retry only; no Apps button.
    private var errorActionBar: some View {
        HStack(spacing: 8) {
            Button { Task { await portfolio.refresh() } } label: {
                HStack(spacing: 5) {
                    Image(systemName: "arrow.clockwise").font(.system(size: 10, weight: .bold))
                    Text("Retry").font(.system(size: 12, weight: .bold))
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
            .keyboardShortcut("r")

            Spacer()

            circleIconButton(symbol: "gearshape.fill", help: "Settings") { showSettings = true }
                .keyboardShortcut(",")
            circleIconButton(symbol: "xmark", help: "Quit ASCBar") { NSApplication.shared.terminate(nil) }
                .keyboardShortcut("q")
        }
    }

    /// State 2 — full controls.
    private var loadedActionBar: some View {
        HStack(spacing: 8) {
            appsButton.keyboardShortcut("a")
            refreshButton.keyboardShortcut("r")
            Spacer()
            circleIconButton(symbol: "gearshape.fill", help: "Settings") { showSettings = true }
                .keyboardShortcut(",")
            circleIconButton(symbol: "xmark", help: "Quit ASCBar") { NSApplication.shared.terminate(nil) }
                .keyboardShortcut("q")
        }
    }

    // MARK: - Shared button shapes

    /// .bar-btn.primary — purple-pink gradient pill
    private var appsButton: some View {
        Button {
            if let app = portfolio.selectedApp {
                handleCopy("asc versions list --app-id \(app.id)")
            }
        } label: {
            HStack(spacing: 5) {
                Image(systemName: "square.grid.2x2").font(.system(size: 10, weight: .bold))
                Text("Apps").font(.system(size: 12, weight: .bold))
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 14)
            .padding(.vertical, 7)
            .background(
                Capsule()
                    .fill(theme.accentGradient)
                    .shadow(color: BaseColors.brandPurple.opacity(0.35), radius: 6, y: 2)
            )
        }
        .buttonStyle(.plain)
    }

    /// .bar-btn.ghost — Refresh / Syncing
    private var refreshButton: some View {
        Button { Task { await portfolio.refresh() } } label: {
            HStack(spacing: 5) {
                Image(systemName: portfolio.isSyncing ? "arrow.triangle.2.circlepath" : "arrow.clockwise")
                    .font(.system(size: 10, weight: .bold))
                    .rotationEffect(portfolio.isSyncing ? .degrees(360) : .zero)
                    .animation(
                        portfolio.isSyncing
                            ? .linear(duration: 1.0).repeatForever(autoreverses: false)
                            : .default,
                        value: portfolio.isSyncing
                    )
                Text(portfolio.isSyncing ? "Syncing" : "Refresh")
                    .font(.system(size: 12, weight: .bold))
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
    }

    private func ghostPill(label: String, icon: String) -> some View {
        HStack(spacing: 5) {
            Image(systemName: icon).font(.system(size: 10, weight: .bold))
            Text(label).font(.system(size: 12, weight: .bold))
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

    /// .icon-btn — 30×30 circle
    private func circleIconButton(symbol: String, help: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(theme.glassBackground)
                    .frame(width: 30, height: 30)
                    .overlay(Circle().stroke(theme.glassBorder, lineWidth: 1))
                Image(systemName: symbol)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(theme.textSecondary)
            }
        }
        .buttonStyle(.plain)
        .help(help)
    }

    // MARK: - Helpers

    private func handleCopy(_ command: String) {
        copyToClipboard(command)
        withAnimation(.spring(response: 0.3)) {
            lastCopiedCommand = command
            copiedConfirmed = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            withAnimation { copiedConfirmed = false; lastCopiedCommand = nil }
        }
    }

    private func copyToClipboard(_ text: String) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
    }
}

// MARK: - Pulsing dot  (.dot.pulse → CSS keyframes pulse)

private struct PulsingDot: View {
    let color: Color
    @State private var pulse = false

    var body: some View {
        ZStack {
            Circle().fill(color.opacity(0.3))
                .frame(width: 14, height: 14)
                .scaleEffect(pulse ? 1.6 : 1.0)
                .opacity(pulse ? 0 : 0.7)
                .animation(.easeOut(duration: 1.0).repeatForever(autoreverses: false), value: pulse)
            Circle().fill(color).frame(width: 7, height: 7)
        }
        .onAppear { pulse = true }
    }
}

// MARK: - Previews (one per core state)

#Preview("State 1 — Loading") {
    MenuContentView(portfolio: AppPortfolio(repository: PreviewRepository(state: .loading)))
        .appThemeProvider(themeModeId: "dark")
}

#Preview("State 2 — Main View") {
    MenuContentView(portfolio: {
        let m = AppPortfolio(repository: PreviewRepository(state: .loaded))
        return m
    }())
    .appThemeProvider(themeModeId: "dark")
}

#Preview("State 3 — Error / No Auth") {
    MenuContentView(portfolio: AppPortfolio(repository: PreviewRepository(state: .error)))
        .appThemeProvider(themeModeId: "dark")
}

// MARK: - Preview repository

private enum PreviewState { case loaded, loading, error }

private final class PreviewRepository: AppStoreRepository {
    let state: PreviewState
    init(state: PreviewState) { self.state = state }

    func fetchApps() async throws -> [ASCApp] {
        switch state {
        case .loading: try? await Task.sleep(for: .seconds(60)); return []
        case .error:   throw URLError(.badServerResponse)
        case .loaded:
            return [
                ASCApp(id: "1", name: "ASCBar",      bundleId: "com.example.ascbar"),
                ASCApp(id: "2", name: "MoneyNotes",  bundleId: "com.example.moneynotes"),
                ASCApp(id: "3", name: "TaskKit Pro", bundleId: "com.example.taskkit"),
                ASCApp(id: "4", name: "WatchLog",    bundleId: "com.example.watchlog"),
            ]
        }
    }

    func fetchVersions(appId: String) async throws -> [ASCVersion] {
        [
            ASCVersion(id: "v1", appId: appId, versionString: "2.0.1", platform: "MAC_OS", state: "READY_FOR_SALE"),
            ASCVersion(id: "v2", appId: appId, versionString: "2.1.0", platform: "MAC_OS", state: "WAITING_FOR_REVIEW"),
            ASCVersion(id: "v3", appId: appId, versionString: "1.0.0", platform: "IOS",    state: "PREPARE_FOR_SUBMISSION"),
            ASCVersion(id: "v4", appId: appId, versionString: "0.9.5", platform: "IOS",    state: "READY_FOR_SALE"),
        ]
    }
}
