import ArgumentParser
import ASCKit

struct AuthLogout: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "logout",
        abstract: "Remove saved authentication credentials"
    )

    @OptionGroup var globals: GlobalOptions

    @Option(name: .long, help: "Account name to remove (defaults to active account)")
    var name: String?

    func run() async throws {
        let storage = ClientProvider.makeAuthStorage()
        try await execute(storage: storage)
    }

    func execute(storage: any AuthStorage) async throws {
        try storage.delete(name: name)
        print("Logged out successfully")
    }
}
