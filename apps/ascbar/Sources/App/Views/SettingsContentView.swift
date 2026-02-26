import SwiftUI
import Domain

/// Inline settings panel shown inside the menu bar popup.
struct SettingsContentView: View {
    @Binding var showSettings: Bool
    let monitor: AppPortfolio

    @Environment(\.appTheme) private var theme
    @State private var settings = AppSettings.shared

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Button(action: { showSettings = false }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(theme.textSecondary)
                }
                .buttonStyle(.plain)

                Text("Settings")
                    .font(.system(size: 14, weight: .semibold, design: theme.fontDesign))
                    .foregroundStyle(theme.textPrimary)

                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 12)

            Divider()
                .background(theme.glassBorder)

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {

                    // MARK: Theme
                    settingSection(title: "Appearance") {
                        HStack(spacing: 8) {
                            ForEach(ThemeRegistry.all, id: \.id) { t in
                                themeButton(theme: t)
                            }
                        }
                    }

                    // MARK: Background Sync
                    settingSection(title: "Background Sync") {
                        Toggle(isOn: $settings.backgroundSyncEnabled) {
                            Text("Auto-refresh every \(Int(settings.backgroundSyncInterval))s")
                                .font(.system(size: 12, design: theme.fontDesign))
                                .foregroundStyle(theme.textSecondary)
                        }
                        .toggleStyle(.switch)
                        .tint(theme.accentPrimary)

                        if settings.backgroundSyncEnabled {
                            Slider(value: $settings.backgroundSyncInterval, in: 30...300, step: 30) {
                                Text("Interval")
                            }
                            .tint(theme.accentPrimary)
                        }
                    }

                    // MARK: Launch at Login
                    settingSection(title: "System") {
                        Toggle(isOn: $settings.launchAtLogin) {
                            Text("Launch at Login")
                                .font(.system(size: 12, design: theme.fontDesign))
                                .foregroundStyle(theme.textSecondary)
                        }
                        .toggleStyle(.switch)
                        .tint(theme.accentPrimary)
                    }

                    // MARK: About
                    settingSection(title: "About") {
                        HStack {
                            Text("ASCBar uses the \(Text("`asc`").font(.system(.caption, design: .monospaced))) CLI")
                                .font(.system(size: 11, design: theme.fontDesign))
                                .foregroundStyle(theme.textTertiary)
                            Spacer()
                        }
                        Text("Make sure `asc auth login` has been run.")
                            .font(.system(size: 11, design: theme.fontDesign))
                            .foregroundStyle(theme.textTertiary)
                    }
                }
                .padding(16)
            }
        }
    }

    // MARK: - Helpers

    private func settingSection<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title.uppercased())
                .font(.system(size: 10, weight: .semibold, design: theme.fontDesign))
                .foregroundStyle(theme.textTertiary)
                .tracking(0.8)

            content()
        }
    }

    private func themeButton(theme t: any AppThemeProvider) -> some View {
        let isSelected = settings.themeMode == t.id
        return Button(action: { settings.themeMode = t.id }) {
            HStack(spacing: 6) {
                Image(systemName: t.icon)
                    .font(.system(size: 11))
                Text(t.displayName)
                    .font(.system(size: 12, weight: isSelected ? .semibold : .regular, design: theme.fontDesign))
            }
            .foregroundStyle(isSelected ? theme.accentPrimary : theme.textSecondary)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(
                RoundedRectangle(cornerRadius: theme.pillCornerRadius)
                    .fill(isSelected ? theme.accentPrimary.opacity(0.15) : theme.glassBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: theme.pillCornerRadius)
                            .strokeBorder(isSelected ? theme.accentPrimary.opacity(0.4) : theme.glassBorder, lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

import Domain
