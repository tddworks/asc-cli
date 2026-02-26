import SwiftUI
import Domain

/// The main menu bar popup — layout mirrors ClaudeBar exactly:
/// circular logo header → app pills → 2-column version card grid → ClaudeBar-style action bar.
struct MenuContentView: View {
    let monitor: AppStoreMonitor

    @Environment(\.appTheme) private var theme
    @State private var showSettings = false
    @State private var animateIn = false

    var body: some View {
        ZStack {
            theme.backgroundGradient
                .ignoresSafeArea()

            if theme.showBackgroundOrbs {
                backgroundOrbs
            }

            if showSettings {
                SettingsContentView(showSettings: $showSettings, monitor: monitor)
            } else {
                mainContent
            }
        }
        .frame(width: 400)
        .fixedSize(horizontal: false, vertical: true)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .task {
            withAnimation(.easeOut(duration: 0.6)) { animateIn = true }
            await monitor.refresh()
        }
    }

    // MARK: - Main Content

    private var mainContent: some View {
        VStack(spacing: 0) {
            headerView
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 12)

            if !monitor.apps.isEmpty {
                appPillsRow
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)
                    .opacity(animateIn ? 1 : 0)
                    .offset(y: animateIn ? 0 : 10)
                    .animation(.easeOut(duration: 0.5).delay(0.1), value: animateIn)
            }

            versionsContent
                .padding(.horizontal, 16)
                .padding(.bottom, 16)

            actionBar
                .padding(.horizontal, 16)
                .padding(.bottom, 12)
                .opacity(animateIn ? 1 : 0)
                .animation(.easeOut(duration: 0.5).delay(0.3), value: animateIn)
        }
    }

    // MARK: - Header (matches ClaudeBar's headerView exactly)

    private var headerView: some View {
        HStack(spacing: 12) {
            // Circular logo
            ZStack {
                Circle()
                    .fill(theme.accentGradient)
                    .frame(width: 38, height: 38)
                    .shadow(color: theme.accentPrimary.opacity(0.3), radius: 8, y: 2)

                Image(systemName: "app.connected.to.app.below.fill")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.white)
            }

            // Title + subtitle
            VStack(alignment: .leading, spacing: 2) {
                Text("ASCBar")
                    .font(.system(size: 18, weight: .bold, design: theme.fontDesign))
                    .foregroundStyle(theme.textPrimary)

                Text("> app monitor")
                    .font(.system(size: 11, weight: .medium, design: theme.fontDesign))
                    .foregroundStyle(theme.textSecondary)
            }

            Spacer()

            // Status badge (Syncing... / Ready / N apps)
            statusBadge
        }
        .opacity(animateIn ? 1 : 0)
        .offset(y: animateIn ? 0 : -10)
        .animation(.easeOut(duration: 0.6), value: animateIn)
    }

    private var statusBadge: some View {
        let color = statusBadgeColor

        return HStack(spacing: 6) {
            if monitor.isSyncing {
                PulsingDot(color: color, isSyncing: true)
            } else {
                Circle()
                    .fill(color)
                    .frame(width: 8, height: 8)
            }

            Text(statusBadgeText)
                .font(.system(size: 11, weight: .medium, design: theme.fontDesign))
                .foregroundStyle(theme.textPrimary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: theme.pillCornerRadius)
                .fill(theme.glassBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: theme.pillCornerRadius)
                        .stroke(color.opacity(0.5), lineWidth: 1)
                )
        )
    }

    private var statusBadgeText: String {
        if monitor.isSyncing { return "Syncing..." }
        if monitor.lastError != nil { return "Error" }
        if monitor.apps.isEmpty { return "No Apps" }
        return "Ready"
    }

    private var statusBadgeColor: Color {
        if monitor.isSyncing { return theme.statusPending }
        if monitor.lastError != nil { return theme.statusRemoved }
        return theme.statusLive
    }

    // MARK: - App Pills

    private var appPillsRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(monitor.apps) { app in
                    AppPillView(
                        app: app,
                        isSelected: monitor.selectedAppId == app.id,
                        onTap: { monitor.selectApp(app.id) }
                    )
                }
            }
        }
    }

    // MARK: - Versions Content

    @ViewBuilder
    private var versionsContent: some View {
        if monitor.isSyncing && monitor.apps.isEmpty {
            loadingView
        } else if let error = monitor.lastError, monitor.apps.isEmpty {
            errorView(error)
        } else if monitor.apps.isEmpty {
            emptyAppsView
        } else {
            VStack(alignment: .leading, spacing: 10) {
                // App name + bundle ID
                if let app = monitor.selectedApp {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(app.displayName)
                            .font(.system(size: 13, weight: .semibold, design: theme.fontDesign))
                            .foregroundStyle(theme.textPrimary)
                        Text(app.bundleId)
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundStyle(theme.textTertiary)
                    }
                    .padding(.horizontal, 4)
                }

                if monitor.selectedVersions.isEmpty && !monitor.isSyncing {
                    Text("No versions found")
                        .font(.system(size: 12, design: theme.fontDesign))
                        .foregroundStyle(theme.textTertiary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 24)
                        .glassCard(cornerRadius: theme.cardCornerRadius)
                } else {
                    // 2-column grid — mirrors ClaudeBar's LazyVGrid for quota cards
                    LazyVGrid(
                        columns: [
                            GridItem(.flexible(), spacing: 10),
                            GridItem(.flexible(), spacing: 10),
                        ],
                        spacing: 10
                    ) {
                        ForEach(monitor.selectedVersions.prefix(6)) { version in
                            VersionCardView(version: version)
                        }
                    }
                    .opacity(animateIn ? 1 : 0)
                    .animation(.easeOut(duration: 0.5).delay(0.2), value: animateIn)
                }
            }
        }
    }

    // MARK: - Action Bar (matches ClaudeBar's actionBar)

    private var actionBar: some View {
        HStack(spacing: 10) {
            // "Apps" pill button (like Dashboard in ClaudeBar)
            appsButton

            // Refresh button (like Syncing in ClaudeBar)
            refreshButton

            Spacer()

            // Settings circle button
            circleButton(icon: "gearshape.fill", help: "Settings") {
                showSettings = true
            }

            // Quit circle button
            circleButton(icon: "xmark", help: "Quit ASCBar") {
                NSApplication.shared.terminate(nil)
            }
        }
    }

    private var appsButton: some View {
        Button {
            // Copy list command to clipboard
            if let app = monitor.selectedApp {
                copyToClipboard("asc versions list --app-id \(app.id)")
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "tray.2.fill")
                    .font(.system(size: 11, weight: .bold))
                Text("Apps")
                    .font(.system(size: 12, weight: .semibold, design: theme.fontDesign))
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: theme.pillCornerRadius)
                    .fill(theme.accentGradient)
                    .shadow(color: theme.accentPrimary.opacity(0.3), radius: 6, y: 2)
            )
        }
        .buttonStyle(.plain)
        .help("Copies `asc versions list` to clipboard")
        .keyboardShortcut("a")
    }

    private var refreshButton: some View {
        Button {
            Task { await monitor.refresh() }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: monitor.isSyncing
                    ? "arrow.trianglehead.2.counterclockwise.rotate.90"
                    : "arrow.clockwise")
                    .font(.system(size: 11, weight: .bold))
                    .rotationEffect(monitor.isSyncing ? .degrees(360) : .degrees(0))
                    .animation(
                        monitor.isSyncing
                            ? .linear(duration: 1.2).repeatForever(autoreverses: false)
                            : .default,
                        value: monitor.isSyncing
                    )
                Text(monitor.isSyncing ? "Syncing" : "Refresh")
                    .font(.system(size: 12, weight: .semibold, design: theme.fontDesign))
            }
            .foregroundStyle(theme.textSecondary)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
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
    }

    private func circleButton(icon: String, help: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(theme.glassBackground)
                    .frame(width: 32, height: 32)

                Image(systemName: icon)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(theme.textSecondary)
            }
        }
        .buttonStyle(.plain)
        .help(help)
    }

    // MARK: - State Views

    private var loadingView: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .stroke(theme.textTertiary, lineWidth: 3)
                    .frame(width: 50, height: 50)

                Circle()
                    .trim(from: 0, to: 0.3)
                    .stroke(
                        theme.accentGradient,
                        style: StrokeStyle(lineWidth: 3, lineCap: .round)
                    )
                    .frame(width: 50, height: 50)
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 1).repeatForever(autoreverses: false), value: animateIn)
            }
            Text("Fetching apps…")
                .font(.system(size: 13, weight: .medium, design: theme.fontDesign))
                .foregroundStyle(theme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }

    private func errorView(_ error: String) -> some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(theme.statusRemoved.opacity(0.2))
                    .frame(width: 60, height: 60)
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(theme.statusRemoved)
            }
            Text("Could not load apps")
                .font(.system(size: 14, weight: .bold, design: theme.fontDesign))
                .foregroundStyle(theme.textPrimary)
            Text(error)
                .font(.system(size: 11, design: theme.fontDesign))
                .foregroundStyle(theme.textSecondary)
                .multilineTextAlignment(.center)
            Text("Run `asc auth login` in Terminal")
                .font(.system(size: 10, design: .monospaced))
                .foregroundStyle(theme.textTertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .glassCard()
    }

    private var emptyAppsView: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(theme.statusProcessing.opacity(0.2))
                    .frame(width: 60, height: 60)
                Image(systemName: "tray")
                    .font(.system(size: 28))
                    .foregroundStyle(theme.textTertiary)
            }
            Text("No apps found")
                .font(.system(size: 14, weight: .bold, design: theme.fontDesign))
                .foregroundStyle(theme.textPrimary)
            Text("Run `asc auth login` in Terminal")
                .font(.system(size: 11, design: .monospaced))
                .foregroundStyle(theme.textTertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .glassCard()
    }

    // MARK: - Background Orbs

    private var backgroundOrbs: some View {
        GeometryReader { geo in
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [BaseColors.purpleVibrant.opacity(0.4), .clear],
                            center: .center,
                            startRadius: 0,
                            endRadius: 120
                        )
                    )
                    .frame(width: 240, height: 240)
                    .offset(x: -60, y: -80)
                    .blur(radius: 40)

                Circle()
                    .fill(
                        RadialGradient(
                            colors: [BaseColors.pinkHot.opacity(0.35), .clear],
                            center: .center,
                            startRadius: 0,
                            endRadius: 100
                        )
                    )
                    .frame(width: 200, height: 200)
                    .offset(x: geo.size.width - 80, y: geo.size.height - 150)
                    .blur(radius: 30)
            }
        }
        .allowsHitTesting(false)
    }

    // MARK: - Helpers

    private func copyToClipboard(_ text: String) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
    }
}

// MARK: - Pulsing Status Dot

private struct PulsingDot: View {
    let color: Color
    let isSyncing: Bool

    @State private var pulse = false

    var body: some View {
        ZStack {
            if isSyncing {
                Circle()
                    .fill(color.opacity(0.3))
                    .frame(width: 16, height: 16)
                    .scaleEffect(pulse ? 1.4 : 1.0)
                    .opacity(pulse ? 0 : 0.8)
                    .animation(.easeOut(duration: 1.0).repeatForever(autoreverses: false), value: pulse)
            }
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
        }
        .onAppear { pulse = true }
    }
}

// MARK: - Glass Card View Modifier

private extension View {
    func glassCard(cornerRadius: CGFloat = 14, padding: CGFloat = 16) -> some View {
        self
            .padding(padding)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(Color.primary.opacity(0.06))
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .stroke(Color.primary.opacity(0.12), lineWidth: 1)
                }
            )
    }
}

// MARK: - Previews

#Preview("Dark — With Apps") {
    MenuContentView(monitor: {
        let m = AppStoreMonitor(repository: PreviewRepository(hasApps: true))
        return m
    }())
    .appThemeProvider(themeModeId: "dark")
    .frame(width: 400)
}

#Preview("Dark — Loading") {
    MenuContentView(monitor: AppStoreMonitor(repository: PreviewRepository(hasApps: false, delay: true)))
        .appThemeProvider(themeModeId: "dark")
        .frame(width: 400)
}

#Preview("Dark — Empty") {
    MenuContentView(monitor: AppStoreMonitor(repository: PreviewRepository(hasApps: false)))
        .appThemeProvider(themeModeId: "dark")
        .frame(width: 400)
}

// MARK: - Preview Repository

private final class PreviewRepository: AppStoreRepository {
    let hasApps: Bool
    let delay: Bool

    init(hasApps: Bool, delay: Bool = false) {
        self.hasApps = hasApps
        self.delay = delay
    }

    func fetchApps() async throws -> [ASCApp] {
        if delay { try? await Task.sleep(for: .seconds(60)) }
        guard hasApps else { return [] }
        return [
            ASCApp(id: "1", name: "MyApp Pro", bundleId: "com.example.myapp"),
            ASCApp(id: "2", name: "SecondApp", bundleId: "com.example.second"),
        ]
    }

    func fetchVersions(appId: String) async throws -> [ASCVersion] {
        [
            ASCVersion(id: "v1", appId: appId, versionString: "1.5.0", platform: "IOS", state: "READY_FOR_SALE"),
            ASCVersion(id: "v2", appId: appId, versionString: "1.6.0", platform: "IOS", state: "PREPARE_FOR_SUBMISSION"),
            ASCVersion(id: "v3", appId: appId, versionString: "1.5.0", platform: "MAC_OS", state: "READY_FOR_SALE"),
            ASCVersion(id: "v4", appId: appId, versionString: "1.6.0", platform: "MAC_OS", state: "WAITING_FOR_REVIEW", buildId: "b1"),
        ]
    }
}
