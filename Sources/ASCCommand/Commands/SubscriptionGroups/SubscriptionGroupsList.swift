import ArgumentParser
import ASCKit

struct SubscriptionGroupsList: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "list",
        abstract: "List subscription groups for an app"
    )

    @OptionGroup var globals: GlobalOptions

    @Option(name: .long, help: "App ID to list subscription groups for")
    var appId: String

    @Option(name: .long, help: "Maximum number of results")
    var limit: Int?

    func run() async throws {
        let repo = try ClientProvider.makeSubscriptionGroups()
        print(try await execute(repo: repo))
    }

    func execute(repo: any SubscriptionGroups, affordanceMode: AffordanceMode = .cli) async throws -> String {
        let response = try await repo.listSubscriptionGroups(appId: appId, limit: limit)
        let formatter = OutputFormatter(format: globals.outputFormat, pretty: globals.pretty)
        return try formatter.formatAgentItems(response.data, affordanceMode: affordanceMode)
    }
}
