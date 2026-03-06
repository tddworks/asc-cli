import ArgumentParser
import Domain

struct UserInvitationsInvite: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "invite",
        abstract: "Send an invitation to join App Store Connect"
    )

    @OptionGroup var globals: GlobalOptions

    @Option(name: .long, help: "Email address of the invitee")
    var email: String

    @Option(name: .long, help: "First name of the invitee")
    var firstName: String

    @Option(name: .long, help: "Last name of the invitee")
    var lastName: String

    @Option(name: .long, help: "Role to assign (repeatable, e.g. --role ADMIN --role DEVELOPER)")
    var role: [String]

    @Flag(name: .long, help: "Grant access to all apps (default: false)")
    var allAppsVisible: Bool = false

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
        let item = try await repo.inviteUser(
            email: email,
            firstName: firstName,
            lastName: lastName,
            roles: domainRoles,
            allAppsVisible: allAppsVisible
        )
        let formatter = OutputFormatter(format: globals.outputFormat, pretty: globals.pretty)
        return try formatter.formatAgentItems(
            [item],
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
