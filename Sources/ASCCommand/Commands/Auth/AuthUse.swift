import ArgumentParser
import Domain
import Infrastructure

struct AuthUse: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "use",
        abstract: "Switch the active App Store Connect account"
    )

    @Argument(help: "Account name to activate")
    var name: String

    func run() async throws {
        let storage = FileAuthStorage()
        try await execute(storage: storage)
    }

    func execute(storage: any AuthStorage) async throws {
        try storage.setActive(name: name)
        print("Switched to account \"\(name)\"")
    }
}
