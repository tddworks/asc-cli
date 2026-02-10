import Foundation
import TauTUI
import Domain
import Infrastructure

@MainActor
final class TUIApp {
    enum Screen {
        case mainMenu
        case appsList
        case appDetail(App)
        case buildsList
        case buildDetail(Build)
        case testFlightMenu
        case betaGroupsList
        case betaTestersList
    }

    private let tui: TUI
    private var currentComponent: Component?
    private var navigationStack: [Screen] = []
    private var exitContinuation: CheckedContinuation<Void, Never>?

    init(tui: TUI) {
        self.tui = tui
    }

    /// Blocks until the user quits the TUI.
    func waitForExit() async {
        await withCheckedContinuation { continuation in
            self.exitContinuation = continuation
        }
    }

    private func quit() {
        tui.stop()
        exitContinuation?.resume()
        exitContinuation = nil
    }

    func navigate(to screen: Screen) {
        if currentComponent != nil {
            navigationStack.append(screen)
        } else {
            navigationStack = [screen]
        }
        showScreen(screen)
    }

    func goBack() {
        guard navigationStack.count > 1 else {
            quit()
            return
        }
        navigationStack.removeLast()
        if let previous = navigationStack.last {
            showScreen(previous)
        }
    }

    private func showScreen(_ screen: Screen) {
        if let current = currentComponent {
            tui.removeChild(current)
        }

        let component: Component
        switch screen {
        case .mainMenu:
            navigationStack = [.mainMenu]
            component = makeMainMenu()
        case .appsList:
            let loader = makeLoadingView(title: "Loading apps...")
            showComponent(loader)
            Task { @MainActor in await self.loadApps() }
            return
        case .appDetail(let app):
            component = makeAppDetail(app)
        case .buildsList:
            let loader = makeLoadingView(title: "Loading builds...")
            showComponent(loader)
            Task { @MainActor in await self.loadBuilds() }
            return
        case .buildDetail(let build):
            component = makeBuildDetail(build)
        case .testFlightMenu:
            component = makeTestFlightMenu()
        case .betaGroupsList:
            let loader = makeLoadingView(title: "Loading beta groups...")
            showComponent(loader)
            Task { @MainActor in await self.loadBetaGroups() }
            return
        case .betaTestersList:
            let loader = makeLoadingView(title: "Loading beta testers...")
            showComponent(loader)
            Task { @MainActor in await self.loadBetaTesters() }
            return
        }

        showComponent(component)
    }

    private func showComponent(_ component: Component) {
        if let current = currentComponent {
            tui.removeChild(current)
        }
        currentComponent = component
        tui.addChild(component)
        tui.setFocus(component)
        tui.requestRender()
    }

    // MARK: - Main Menu

    private func makeMainMenu() -> Component {
        let items = [
            SelectItem(value: "apps", label: "Apps", description: "Browse your apps"),
            SelectItem(value: "builds", label: "Builds", description: "Browse builds"),
            SelectItem(value: "testflight", label: "TestFlight", description: "Beta groups & testers"),
            SelectItem(value: "quit", label: "Quit", description: "Exit the TUI"),
        ]
        let list = SelectList(items: items)
        list.onSelect = { [weak self] item in
            guard let self else { return }
            switch item.value {
            case "apps":
                self.navigate(to: .appsList)
            case "builds":
                self.navigate(to: .buildsList)
            case "testflight":
                self.navigate(to: .testFlightMenu)
            case "quit":
                self.quit()
            default:
                break
            }
        }
        list.onCancel = { [weak self] in
            self?.quit()
        }
        return list
    }

    // MARK: - Apps

    private func loadApps() async {
        do {
            let repo = try ClientProvider.makeAppRepository()
            let response = try await repo.listApps(limit: nil)
            let items = response.data.map { app in
                SelectItem(value: app.id, label: app.displayName, description: app.bundleId)
            }
            let list = SelectList(items: items)
            list.onSelect = { [weak self] item in
                if let app = response.data.first(where: { $0.id == item.value }) {
                    self?.navigate(to: .appDetail(app))
                }
            }
            list.onCancel = { [weak self] in
                self?.goBack()
            }
            showComponent(list)
        } catch {
            showComponent(makeErrorView(error: error))
        }
    }

    private func makeAppDetail(_ app: App) -> Component {
        let lines = [
            "App Detail",
            String(repeating: "─", count: 40),
            "ID:      \(app.id)",
            "Name:    \(app.displayName)",
            "Bundle:  \(app.bundleId)",
            "SKU:     \(app.sku ?? "-")",
            "Locale:  \(app.primaryLocale ?? "-")",
            "",
            "Press Escape to go back",
        ]
        return makeTextView(lines: lines)
    }

    // MARK: - Builds

    private func loadBuilds() async {
        do {
            let repo = try ClientProvider.makeBuildRepository()
            let response = try await repo.listBuilds(appId: nil, limit: nil)
            let items = response.data.map { build in
                let state = build.processingState.rawValue
                let expired = build.expired ? " (expired)" : ""
                let buildNum = build.buildNumber.map { " (\($0))" } ?? ""
                return SelectItem(
                    value: build.id,
                    label: "v\(build.version)\(buildNum)",
                    description: "\(state)\(expired)"
                )
            }
            let list = SelectList(items: items)
            list.onSelect = { [weak self] item in
                if let build = response.data.first(where: { $0.id == item.value }) {
                    self?.navigate(to: .buildDetail(build))
                }
            }
            list.onCancel = { [weak self] in
                self?.goBack()
            }
            showComponent(list)
        } catch {
            showComponent(makeErrorView(error: error))
        }
    }

    private func makeBuildDetail(_ build: Build) -> Component {
        let lines = [
            "Build Detail",
            String(repeating: "─", count: 40),
            "ID:       \(build.id)",
            "Version:  \(build.version)",
            "Build #:  \(build.buildNumber ?? "-")",
            "State:    \(build.processingState.rawValue)",
            "Expired:  \(build.expired ? "Yes" : "No")",
            "Usable:   \(build.isUsable ? "Yes" : "No")",
            "",
            "Press Escape to go back",
        ]
        return makeTextView(lines: lines)
    }

    // MARK: - TestFlight

    private func makeTestFlightMenu() -> Component {
        let items = [
            SelectItem(value: "groups", label: "Beta Groups", description: "Browse beta groups"),
            SelectItem(value: "testers", label: "Beta Testers", description: "Browse beta testers"),
        ]
        let list = SelectList(items: items)
        list.onSelect = { [weak self] item in
            switch item.value {
            case "groups":
                self?.navigate(to: .betaGroupsList)
            case "testers":
                self?.navigate(to: .betaTestersList)
            default:
                break
            }
        }
        list.onCancel = { [weak self] in
            self?.goBack()
        }
        return list
    }

    private func loadBetaGroups() async {
        do {
            let repo = try ClientProvider.makeTestFlightRepository()
            let response = try await repo.listBetaGroups(appId: nil, limit: nil)
            let items = response.data.map { group in
                let type = group.isInternalGroup ? "Internal" : "External"
                return SelectItem(value: group.id, label: group.name, description: type)
            }
            let list = SelectList(items: items)
            list.onSelect = { [weak self] item in
                guard let self else { return }
                if let group = response.data.first(where: { $0.id == item.value }) {
                    let lines = [
                        "Beta Group Detail",
                        String(repeating: "─", count: 40),
                        "ID:           \(group.id)",
                        "Name:         \(group.name)",
                        "Internal:     \(group.isInternalGroup ? "Yes" : "No")",
                        "Public Link:  \(group.publicLinkEnabled ? "Yes" : "No")",
                        "",
                        "Press Escape to go back",
                    ]
                    self.showComponent(self.makeTextView(lines: lines))
                }
            }
            list.onCancel = { [weak self] in
                self?.goBack()
            }
            showComponent(list)
        } catch {
            showComponent(makeErrorView(error: error))
        }
    }

    private func loadBetaTesters() async {
        do {
            let repo = try ClientProvider.makeTestFlightRepository()
            let response = try await repo.listBetaTesters(groupId: nil, limit: nil)
            let items = response.data.map { tester in
                SelectItem(
                    value: tester.id,
                    label: tester.displayName,
                    description: tester.email ?? "-"
                )
            }
            let list = SelectList(items: items)
            list.onSelect = { [weak self] item in
                guard let self else { return }
                if let tester = response.data.first(where: { $0.id == item.value }) {
                    let lines = [
                        "Beta Tester Detail",
                        String(repeating: "─", count: 40),
                        "ID:      \(tester.id)",
                        "Name:    \(tester.displayName)",
                        "Email:   \(tester.email ?? "-")",
                        "Invite:  \(tester.inviteType?.rawValue ?? "-")",
                        "",
                        "Press Escape to go back",
                    ]
                    self.showComponent(self.makeTextView(lines: lines))
                }
            }
            list.onCancel = { [weak self] in
                self?.goBack()
            }
            showComponent(list)
        } catch {
            showComponent(makeErrorView(error: error))
        }
    }

    // MARK: - Helpers

    private func makeLoadingView(title: String) -> Component {
        Text(text: title)
    }

    private func makeErrorView(error: Error) -> Component {
        makeTextView(lines: [
            "Error",
            String(repeating: "─", count: 40),
            error.localizedDescription,
            "",
            "Press Escape to go back",
        ])
    }

    private func makeTextView(lines: [String]) -> Component {
        let text = Text(text: lines.joined(separator: "\n"))
        return EscapeWrapper(inner: text) { [weak self] in
            MainActor.assumeIsolated {
                self?.goBack()
            }
        }
    }
}

/// Wraps a component to handle Escape key for back-navigation.
final class EscapeWrapper: Component {
    private let inner: Component
    private let onEscape: @Sendable () -> Void

    init(inner: Component, onEscape: @escaping @Sendable () -> Void) {
        self.inner = inner
        self.onEscape = onEscape
    }

    func render(width: Int) -> [String] {
        inner.render(width: width)
    }

    func handle(input: TerminalInput) {
        if case .key(.escape, modifiers: []) = input {
            onEscape()
        } else {
            inner.handle(input: input)
        }
    }
}
