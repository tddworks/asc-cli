import ArgumentParser
import ASCKit

struct UsersRemove: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "remove",
        abstract: "Remove a team member from App Store Connect"
    )

    @OptionGroup var globals: GlobalOptions

    @Option(name: .long, help: "User resource ID")
    var userId: String

    func run() async throws {
        let repo = try ClientProvider.makeUsers()
        try await execute(repo: repo)
    }

    func execute(repo: any Users) async throws {
        try await repo.removeUser(id: userId)
    }
}
