import ArgumentParser
import ASCKit

struct SubscriptionsList: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "list",
        abstract: "List subscriptions in a subscription group"
    )

    @OptionGroup var globals: GlobalOptions

    @Option(name: .long, help: "Subscription group ID")
    var groupId: String

    @Option(name: .long, help: "Maximum number of results")
    var limit: Int?

    func run() async throws {
        let repo = try ClientProvider.makeSubscriptions()
        print(try await execute(repo: repo))
    }

    func execute(
        repo: any Subscriptions,
        affordanceMode: AffordanceMode = .cli
    ) async throws -> String {
        let response = try await repo.listSubscriptions(groupId: groupId, limit: limit)
        let formatter = OutputFormatter(format: globals.outputFormat, pretty: globals.pretty)
        return try formatter.formatAgentItems(response.data, affordanceMode: affordanceMode)
    }
}
