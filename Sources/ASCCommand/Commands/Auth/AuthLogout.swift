import ArgumentParser
import Domain
import Infrastructure

struct AuthLogout: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "logout",
        abstract: "Remove saved authentication credentials"
    )

    func run() async throws {
        let storage = FileAuthStorage()
        try await execute(storage: storage)
    }

    func execute(storage: any AuthStorage) async throws {
        try storage.delete()
        print("Logged out successfully")
    }
}
