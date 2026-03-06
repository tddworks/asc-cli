import ArgumentParser
import Domain

struct UsersUpdate: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "update",
        abstract: "Update a team member's roles"
    )

    @OptionGroup var globals: GlobalOptions

    @Option(name: .long, help: "User resource ID")
    var userId: String

    @Option(name: .long, help: "Role to assign (repeatable, e.g. --role ADMIN --role DEVELOPER)")
    var role: [String]

    func run() async throws {
        let repo = try ClientProvider.makeUserRepository()
        print(try await execute(repo: repo))
    }

    func execute(repo: any UserRepository) async throws -> String {
        let domainRoles = try role.map { raw -> UserRole in
            guard let r = UserRole(cliArgument: raw) else {
                throw ValidationError("Invalid role '\(raw)'. Valid values: \(UserRole.allCases.map(\.rawValue).joined(separator: ", "))")
            }
            return r
        }
        guard !domainRoles.isEmpty else {
            throw ValidationError("At least one --role is required.")
        }
        let item = try await repo.updateUser(id: userId, roles: domainRoles)
        let formatter = OutputFormatter(format: globals.outputFormat, pretty: globals.pretty)
        return try formatter.formatAgentItems(
            [item],
            headers: ["ID", "Username", "Name", "Roles", "All Apps"],
            rowMapper: { [
                $0.id,
                $0.username,
                "\($0.firstName) \($0.lastName)",
                $0.roles.map(\.rawValue).joined(separator: ", "),
                $0.isAllAppsVisible ? "Yes" : "No",
            ] }
        )
    }
}
