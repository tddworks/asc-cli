import ArgumentParser
import Domain
import Infrastructure

struct AuthLogout: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "logout",
        abstract: "Remove saved authentication credentials"
    )

    @Option(name: .long, help: "Account name to remove (defaults to active account)")
    var name: String?

    func run() async throws {
        let storage = FileAuthStorage()
        try await execute(storage: storage)
    }

    func execute(storage: any AuthStorage) async throws {
        try storage.delete(name: name)
        print("Logged out successfully")
    }
}
