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
        return try formatter.formatAgentItems(
            items,
            headers: ["ID", "Email", "Name", "Roles", "All Apps"],
            rowMapper: { [
                $0.id,
                $0.email,
                "\($0.firstName) \($0.lastName)",
                $0.roles.map(\.rawValue).joined(separator: ", "),
                $0.isAllAppsVisible ? "Yes" : "No",
            ] }
        )
    }
}
