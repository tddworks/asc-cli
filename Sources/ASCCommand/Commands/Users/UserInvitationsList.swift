import ArgumentParser
import Domain

struct UserInvitationsList: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "list",
        abstract: "List pending user invitations"
    )

    @OptionGroup var globals: GlobalOptions

    @Option(name: .long, help: "Filter by role (e.g. ADMIN, DEVELOPER)")
    var role: String?

    func run() async throws {
        let repo = try ClientProvider.makeUserRepository()
        print(try await execute(repo: repo))
    }

    func execute(repo: any UserRepository) async throws -> String {
        let domainRole = role.flatMap { UserRole(cliArgument: $0) }
        let items = try await repo.listUserInvitations(role: domainRole)
        let formatter = OutputFormatter(format: globals.outputFormat, pretty: globals.pretty)
        return try formatter.formatAgentItems(items)
    }
}
