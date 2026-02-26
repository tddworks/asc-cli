import SwiftUI
import Shimmer
import Domain

/// Main menu bar popup — layout matches ux-prototype.html exactly:
/// header → app pills → app meta → 2-col version grid → (code snippet toast) → action bar.
struct MenuContentView: View {
    let portfolio: AppPortfolio

    @Environment(\.appTheme) private var theme
    @State private var showSettings = false
    @State private var animateIn = false
    /// The last CLI command copied — drives the code-snippet toast bar.
    @State private var lastCopiedCommand: String? = nil
    @State private var copiedConfirmed = false

    var body: some View {
        ZStack {
            theme.backgroundGradient.ignoresSafeArea()

            if theme.showBackgroundOrbs { backgroundOrbs }

            if showSettings {
                SettingsContentView(showSettings: $showSettings, monitor: portfolio)
            } else {
                mainContent
            }
        }
        .frame(width: 400)
        .fixedSize(horizontal: false, vertical: true)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .task {
            withAnimation(.easeOut(duration: 0.4)) { animateIn = true }
            await portfolio.refresh()
        }
    }

    // MARK: - Main Content

    private var mainContent: some View {
        VStack(spacing: 0) {
            header
                .padding(.horizontal, 16)
                .padding(.top, 14)
                .padding(.bottom, 10)
                .overlay(alignment: .bottom) {
                    Divider().background(theme.glassBorder)
                }

            if !portfolio.apps.isEmpty {
                appPillsRow
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .overlay(alignment: .bottom) {
                        Divider().background(theme.glassBorder)
                    }
            }

            versionsSection
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 8)

            // Code-snippet toast — appears after copy
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
                .overlay(alignment: .top) {
                    Divider().background(theme.glassBorder)
                }
        }
        .animation(.easeOut(duration: 0.2), value: lastCopiedCommand)
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: 12) {
            // Brand logo circle with purple-pink gradient
            ZStack {
                Circle()
                    .fill(theme.accentGradient)
                    .frame(width: 36, height: 36)
                    .shadow(color: BaseColors.brandPurple.opacity(0.45), radius: 8, y: 2)

                Image(systemName: "square.grid.2x2.fill")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.white)
            }

            VStack(alignment: .leading, spacing: 1) {
                Text("ASCBar")
                    .font(.system(size: 16, weight: .bold, design: theme.fontDesign))
                    .foregroundStyle(theme.textPrimary)
                Text("> app monitor")
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundStyle(theme.textSecondary)
            }

            Spacer()

            statusPill
        }
        .opacity(animateIn ? 1 : 0)
        .offset(y: animateIn ? 0 : -6)
        .animation(.easeOut(duration: 0.4), value: animateIn)
    }

    private var statusPill: some View {
        HStack(spacing: 5) {
            statusDot
            Text(statusText)
                .font(.system(size: 11, weight: .semibold, design: theme.fontDesign))
                .foregroundStyle(theme.textPrimary)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: theme.pillCornerRadius)
                .fill(theme.glassBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: theme.pillCornerRadius)
                        .stroke(theme.glassBorder, lineWidth: 1)
                )
        )
    }

    @ViewBuilder
    private var statusDot: some View {
        if portfolio.isSyncing {
            PulsingDot(color: theme.accentPrimary)
        } else if portfolio.lastError != nil {
            Circle().fill(theme.statusRemoved)
                .frame(width: 7, height: 7)
                .shadow(color: theme.statusRemoved, radius: 3)
        } else {
            Circle().fill(theme.statusLive)
                .frame(width: 7, height: 7)
                .shadow(color: theme.statusLive, radius: 3)
        }
    }

    private var statusText: String {
        if portfolio.isSyncing   { return "Syncing…" }
        if portfolio.lastError != nil { return "Error" }
        return "Ready"
    }

    // MARK: - App Pills

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

    // MARK: - Versions Section

    @ViewBuilder
    private var versionsSection: some View {
        if portfolio.isSyncing && portfolio.apps.isEmpty {
            shimmerGrid
        } else if let error = portfolio.lastError, portfolio.apps.isEmpty {
            errorCard(error)
        } else if portfolio.apps.isEmpty {
            emptyCard
        } else {
            VStack(alignment: .leading, spacing: 8) {
                // App name + bundle ID
                if let app = portfolio.selectedApp {
                    VStack(alignment: .leading, spacing: 1) {
                        Text(app.displayName)
                            .font(.system(size: 13, weight: .bold, design: theme.fontDesign))
                            .foregroundStyle(theme.textPrimary)
                        Text(app.bundleId)
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundStyle(theme.textTertiary)
                    }
                }

                if portfolio.isSyncing {
                    shimmerGrid
                } else if portfolio.selectedVersions.isEmpty {
                    Text("No versions found")
                        .font(.system(size: 12, design: theme.fontDesign))
                        .foregroundStyle(theme.textTertiary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 24)
                } else {
                    LazyVGrid(
                        columns: [GridItem(.flexible(), spacing: 8), GridItem(.flexible(), spacing: 8)],
                        spacing: 8
                    ) {
                        ForEach(portfolio.selectedVersions.prefix(6)) { version in
                            VersionCardView(version: version) { cmd in
                                handleCopy(cmd)
                            }
                        }
                    }
                    .opacity(animateIn ? 1 : 0)
                    .animation(.easeOut(duration: 0.4).delay(0.1), value: animateIn)
                }
            }
        }
    }

    // MARK: - Shimmer Skeleton Grid (loading state)

    private var shimmerGrid: some View {
        LazyVGrid(
            columns: [GridItem(.flexible(), spacing: 8), GridItem(.flexible(), spacing: 8)],
            spacing: 8
        ) {
            ForEach(0..<4, id: \.self) { _ in
                skeletonCard
            }
        }
    }

    private var skeletonCard: some View {
        VStack(alignment: .leading, spacing: 6) {
            RoundedRectangle(cornerRadius: 3).fill(theme.glassBorder)
                .frame(width: 36, height: 9)
                .shimmering(
                    animation: .easeInOut(duration: 1.4).repeatForever(autoreverses: false),
                    gradient: Gradient(colors: [
                        theme.glassBorder,
                        theme.glassHighlight,
                        theme.glassBorder,
                    ])
                )
            RoundedRectangle(cornerRadius: 3).fill(theme.glassBorder)
                .frame(width: 60, height: 22)
                .shimmering(
                    animation: .easeInOut(duration: 1.4).repeatForever(autoreverses: false),
                    gradient: Gradient(colors: [
                        theme.glassBorder,
                        theme.glassHighlight,
                        theme.glassBorder,
                    ])
                )
            RoundedRectangle(cornerRadius: 3).fill(theme.glassBorder)
                .frame(width: 80, height: 11)
                .shimmering(
                    animation: .easeInOut(duration: 1.4).repeatForever(autoreverses: false),
                    gradient: Gradient(colors: [
                        theme.glassBorder,
                        theme.glassHighlight,
                        theme.glassBorder,
                    ])
                )
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: theme.cardCornerRadius)
                .fill(theme.glassBackground.opacity(0.5))
                .overlay(
                    RoundedRectangle(cornerRadius: theme.cardCornerRadius)
                        .stroke(theme.glassBorder, lineWidth: 1)
                )
        )
    }

    // MARK: - Code Snippet Toast

    private func codeSnippetBar(_ command: String) -> some View {
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
                    withAnimation {
                        copiedConfirmed = false
                        lastCopiedCommand = nil
                    }
                }
            } label: {
                Text(copiedConfirmed ? "✓ Copied!" : "Copy")
                    .font(.system(size: 10, weight: .bold, design: theme.fontDesign))
                    .foregroundStyle(copiedConfirmed ? theme.statusLive : theme.accentPrimary)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 2)
                    .background(
                        RoundedRectangle(cornerRadius: 4)
                            .fill(
                                copiedConfirmed
                                    ? theme.statusLive.opacity(0.12)
                                    : theme.accentPrimary.opacity(0.12)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 4)
                                    .stroke(
                                        copiedConfirmed
                                            ? theme.statusLive.opacity(0.25)
                                            : theme.accentPrimary.opacity(0.25),
                                        lineWidth: 1
                                    )
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

    // MARK: - Action Bar

    private var actionBar: some View {
        HStack(spacing: 8) {
            // "Apps" — primary gradient pill (matches .bar-btn.primary)
            Button {
                if let app = portfolio.selectedApp {
                    handleCopy("asc versions list --app-id \(app.id)")
                }
            } label: {
                HStack(spacing: 5) {
                    Image(systemName: "square.grid.2x2")
                        .font(.system(size: 10, weight: .bold))
                    Text("Apps")
                        .font(.system(size: 12, weight: .bold, design: theme.fontDesign))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(
                    RoundedRectangle(cornerRadius: theme.pillCornerRadius)
                        .fill(theme.accentGradient)
                        .shadow(color: BaseColors.brandPurple.opacity(0.35), radius: 6, y: 2)
                )
            }
            .buttonStyle(.plain)
            .keyboardShortcut("a")

            // "Refresh" — ghost pill (matches .bar-btn.ghost)
            Button { Task { await portfolio.refresh() } } label: {
                HStack(spacing: 5) {
                    Image(systemName: portfolio.isSyncing
                          ? "arrow.triangle.2.circlepath"
                          : "arrow.clockwise")
                        .font(.system(size: 10, weight: .bold))
                        .rotationEffect(portfolio.isSyncing ? .degrees(360) : .zero)
                        .animation(
                            portfolio.isSyncing
                                ? .linear(duration: 1.0).repeatForever(autoreverses: false)
                                : .default,
                            value: portfolio.isSyncing
                        )
                    Text(portfolio.isSyncing ? "Syncing" : "Refresh")
                        .font(.system(size: 12, weight: .bold, design: theme.fontDesign))
                }
                .foregroundStyle(theme.textSecondary)
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(
                    RoundedRectangle(cornerRadius: theme.pillCornerRadius)
                        .fill(theme.glassBackground)
                        .overlay(
                            RoundedRectangle(cornerRadius: theme.pillCornerRadius)
                                .stroke(theme.glassBorder, lineWidth: 1)
                        )
                )
            }
            .buttonStyle(.plain)
            .keyboardShortcut("r")

            Spacer()

            // Settings icon button (circle)
            iconButton(symbol: "gearshape.fill", help: "Settings") { showSettings = true }
                .keyboardShortcut(",")

            // Quit icon button (circle)
            iconButton(symbol: "xmark", help: "Quit ASCBar") {
                NSApplication.shared.terminate(nil)
            }
            .keyboardShortcut("q")
        }
    }

    private func iconButton(symbol: String, help: String, action: @escaping () -> Void) -> some View {
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

    // MARK: - Error / Empty Cards

    private func errorCard(_ error: String) -> some View {
        VStack(spacing: 12) {
            VStack(spacing: 6) {
                Text("⚠️").font(.system(size: 32))
                Text("Could not load apps")
                    .font(.system(size: 14, weight: .bold, design: theme.fontDesign))
                    .foregroundStyle(theme.textPrimary)
                Text("No credentials found.\nRun the command below in Terminal.")
                    .font(.system(size: 11, design: theme.fontDesign))
                    .foregroundStyle(theme.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, 8)

            // Code snippet for auth
            HStack {
                Text("$ asc auth login")
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundStyle(theme.textMono)
                Spacer()
                Button("Copy") { handleCopy("asc auth login") }
                    .font(.system(size: 10, weight: .bold, design: theme.fontDesign))
                    .foregroundStyle(theme.accentPrimary)
                    .buttonStyle(.plain)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.black.opacity(0.35))
                    .overlay(RoundedRectangle(cornerRadius: 8)
                        .stroke(theme.textMono.opacity(0.15), lineWidth: 1))
            )
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: theme.cardCornerRadius)
                .fill(theme.statusRemoved.opacity(0.06))
                .overlay(RoundedRectangle(cornerRadius: theme.cardCornerRadius)
                    .stroke(theme.statusRemoved.opacity(0.18), lineWidth: 1))
        )
        .padding(.bottom, 4)
    }

    private var emptyCard: some View {
        VStack(spacing: 8) {
            Text("📭").font(.system(size: 32))
            Text("No apps found")
                .font(.system(size: 14, weight: .bold, design: theme.fontDesign))
                .foregroundStyle(theme.textPrimary)
            Text("Make sure `asc auth login` was run.")
                .font(.system(size: 11, design: .monospaced))
                .foregroundStyle(theme.textTertiary)
        }
        .padding(24)
        .frame(maxWidth: .infinity)
    }

    // MARK: - Background Orbs

    private var backgroundOrbs: some View {
        GeometryReader { geo in
            ZStack {
                Circle()
                    .fill(RadialGradient(
                        colors: [BaseColors.brandPurple.opacity(0.35), .clear],
                        center: .center, startRadius: 0, endRadius: 120))
                    .frame(width: 220, height: 220)
                    .offset(x: -60, y: -80)
                    .blur(radius: 40)

                Circle()
                    .fill(RadialGradient(
                        colors: [BaseColors.brandPink.opacity(0.28), .clear],
                        center: .center, startRadius: 0, endRadius: 100))
                    .frame(width: 180, height: 180)
                    .offset(x: geo.size.width - 40, y: geo.size.height - 60)
                    .blur(radius: 30)
            }
        }
        .allowsHitTesting(false)
    }

    // MARK: - Helpers

    private func handleCopy(_ command: String) {
        copyToClipboard(command)
        withAnimation(.spring(response: 0.3)) {
            lastCopiedCommand = command
            copiedConfirmed = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            withAnimation {
                copiedConfirmed = false
                lastCopiedCommand = nil
            }
        }
    }

    private func copyToClipboard(_ text: String) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
    }
}

// MARK: - Pulsing Status Dot

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

// MARK: - Previews

#Preview("Dark — Main") {
    MenuContentView(portfolio: {
        let m = AppPortfolio(repository: PreviewRepository(state: .loaded))
        return m
    }())
    .appThemeProvider(themeModeId: "dark")
    .frame(width: 400)
}

#Preview("Dark — Loading") {
    MenuContentView(portfolio: AppPortfolio(repository: PreviewRepository(state: .loading)))
        .appThemeProvider(themeModeId: "dark")
        .frame(width: 400)
}

#Preview("Dark — Error") {
    MenuContentView(portfolio: AppPortfolio(repository: PreviewRepository(state: .error)))
        .appThemeProvider(themeModeId: "dark")
        .frame(width: 400)
}

// MARK: - Preview Repository

private enum PreviewState { case loaded, loading, error }

private final class PreviewRepository: AppStoreRepository {
    let state: PreviewState
    init(state: PreviewState) { self.state = state }

    func fetchApps() async throws -> [ASCApp] {
        switch state {
        case .loading: try? await Task.sleep(for: .seconds(60)); return []
        case .error: throw URLError(.badServerResponse)
        case .loaded:
            return [
                ASCApp(id: "1", name: "ASCBar", bundleId: "com.example.ascbar"),
                ASCApp(id: "2", name: "MoneyNotes", bundleId: "com.example.moneynotes"),
                ASCApp(id: "3", name: "TaskKit Pro", bundleId: "com.example.taskkit"),
            ]
        }
    }

    func fetchVersions(appId: String) async throws -> [ASCVersion] {
        [
            ASCVersion(id: "v1", appId: appId, versionString: "2.0.1", platform: "MAC_OS", state: "READY_FOR_SALE"),
            ASCVersion(id: "v2", appId: appId, versionString: "2.1.0", platform: "MAC_OS", state: "WAITING_FOR_REVIEW"),
            ASCVersion(id: "v3", appId: appId, versionString: "1.0.0", platform: "IOS", state: "PREPARE_FOR_SUBMISSION"),
            ASCVersion(id: "v4", appId: appId, versionString: "0.9.5", platform: "IOS", state: "READY_FOR_SALE"),
        ]
    }
}
