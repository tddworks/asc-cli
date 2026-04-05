import ArgumentParser
import Domain

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
        let repo = try ClientProvider.makeSubscriptionGroupRepository()
        print(try await execute(repo: repo))
    }

    func execute(repo: any SubscriptionGroupRepository, affordanceMode: AffordanceMode = .cli) async throws -> String {
        let response = try await repo.listSubscriptionGroups(appId: appId, limit: limit)
        let formatter = OutputFormatter(format: globals.outputFormat, pretty: globals.pretty)
        return try formatter.formatAgentItems(
            response.data,
            headers: ["ID", "Reference Name"],
            rowMapper: { [$0.id, $0.referenceName] },
            affordanceMode: affordanceMode
        )
    }
}
