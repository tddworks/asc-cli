import ArgumentParser
import Foundation
import TauTUI

struct TUICommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "tui",
        abstract: "Interactive terminal UI"
    )

    @MainActor
    func run() async throws {
        let terminal = ProcessTerminal()
        let tui = TUI(terminal: terminal)

        let app = TUIApp(tui: tui)
        app.navigate(to: .mainMenu)

        try tui.start()

        // Keep the process alive until TUI exits (via exit(0) in TUIApp)
        await withCheckedContinuation { (_: CheckedContinuation<Void, Never>) in
            // Never resumes — TUIApp calls exit(0) when user quits
        }
    }
}
