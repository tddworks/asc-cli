import SwiftUI
import Domain
import Infrastructure

@main
struct ASCBarApp: App {
    @State private var portfolio: AppPortfolio
    @State private var settings = AppSettings.shared

    init() {
        _portfolio = State(initialValue: AppPortfolio(repository: CLIAppStoreRepository()))
    }

    var body: some Scene {
        MenuBarExtra {
            MenuContentView(portfolio: portfolio)
                .appThemeProvider(themeModeId: settings.themeMode)
                .task {
                    await portfolio.refresh()
                    if settings.backgroundSyncEnabled {
                        portfolio.startAutoRefresh(interval: settings.backgroundSyncInterval)
                    }
                }
                .onChange(of: settings.backgroundSyncEnabled) { _, enabled in
                    if enabled {
                        portfolio.startAutoRefresh(interval: settings.backgroundSyncInterval)
                    } else {
                        portfolio.stopAutoRefresh()
                    }
                }
        } label: {
            StatusBarIcon(status: portfolio.overallStatus, isSyncing: portfolio.isSyncing)
                .appThemeProvider(themeModeId: settings.themeMode)
        }
        .menuBarExtraStyle(.window)
    }
}

// MARK: - Status Bar Icon

/// Menu bar icon — shows the portfolio's most urgent status; spins while fetching.
struct StatusBarIcon: View {
    let status: AppStatus
    let isSyncing: Bool

    @Environment(\.appTheme) private var theme

    var body: some View {
        Image(systemName: isSyncing ? "arrow.triangle.2.circlepath" : iconName)
            .font(.system(size: 12, weight: .medium))
            .foregroundStyle(theme.statusColor(for: status).opacity(isSyncing ? 0.7 : 1.0))
    }

    private var iconName: String {
        switch status {
        case .editable:   return "app.fill"
        case .pending:    return "clock.badge.fill"
        case .live:       return "app.badge.checkmark.fill"
        case .removed:    return "app.badge.fill"
        case .processing: return "app.fill"
        }
    }
}
