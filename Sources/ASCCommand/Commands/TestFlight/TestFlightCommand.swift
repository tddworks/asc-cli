import ArgumentParser
import Domain

struct TestFlightCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "testflight",
        abstract: "Manage TestFlight beta testing",
        subcommands: [BetaGroupsList.self, BetaTestersList.self]
    )
}

struct BetaGroupsList: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "groups",
        abstract: "List beta groups"
    )

    @OptionGroup var globals: GlobalOptions

    @Option(name: .long, help: "Filter by app ID")
    var app: String?

    @Option(name: .long, help: "Maximum number of groups to return")
    var limit: Int?

    func run() async throws {
        let repo = try ClientProvider.makeTestFlightRepository()
        print(try await execute(repo: repo))
    }

    func execute(repo: any TestFlightRepository) async throws -> String {
        let response = try await repo.listBetaGroups(appId: app, limit: limit)
        let formatter = OutputFormatter(format: globals.outputFormat, pretty: globals.pretty)
        return try formatter.formatItems(
            response.data,
            headers: ["ID", "Name", "Internal", "Public Link"],
            rowMapper: { [$0.id, $0.name, $0.isInternalGroup ? "Yes" : "No", $0.publicLinkEnabled ? "Yes" : "No"] }
        )
    }
}

struct BetaTestersList: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "testers",
        abstract: "List beta testers"
    )

    @OptionGroup var globals: GlobalOptions

    @Option(name: .long, help: "Filter by beta group ID")
    var group: String?

    @Option(name: .long, help: "Maximum number of testers to return")
    var limit: Int?

    func run() async throws {
        let repo = try ClientProvider.makeTestFlightRepository()
        print(try await execute(repo: repo))
    }

    func execute(repo: any TestFlightRepository) async throws -> String {
        let response = try await repo.listBetaTesters(groupId: group, limit: limit)
        let formatter = OutputFormatter(format: globals.outputFormat, pretty: globals.pretty)
        return try formatter.formatItems(
            response.data,
            headers: ["ID", "Name", "Email", "Invite Type"],
            rowMapper: { [$0.id, $0.displayName, $0.email ?? "-", $0.inviteType?.rawValue ?? "-"] }
        )
    }
}
