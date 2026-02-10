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
        let repos = try ClientProvider.makeRepositories()
        let response = try await repos.testFlight.listBetaGroups(appId: app, limit: limit)
        let formatter = OutputFormatter(format: globals.outputFormat, pretty: globals.pretty)

        let output = try formatter.formatItems(
            response.data,
            headers: ["ID", "Name", "Internal", "Public Link"],
            rowMapper: { group in
                [group.id, group.name, group.isInternalGroup ? "Yes" : "No", group.publicLinkEnabled ? "Yes" : "No"]
            }
        )
        print(output)
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
        let repos = try ClientProvider.makeRepositories()
        let response = try await repos.testFlight.listBetaTesters(groupId: group, limit: limit)
        let formatter = OutputFormatter(format: globals.outputFormat, pretty: globals.pretty)

        let output = try formatter.formatItems(
            response.data,
            headers: ["ID", "Name", "Email", "Invite Type"],
            rowMapper: { tester in
                [tester.id, tester.displayName, tester.email ?? "-", tester.inviteType?.rawValue ?? "-"]
            }
        )
        print(output)
    }
}
