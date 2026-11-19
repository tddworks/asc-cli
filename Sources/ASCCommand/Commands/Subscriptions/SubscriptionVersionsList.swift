import ArgumentParser
import ASCKit

struct SubscriptionVersionsList: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "list",
        abstract: "List review versions of a subscription (add a submittable one to a review submission)"
    )

    @OptionGroup var globals: GlobalOptions

    @Option(name: .long, help: "Subscription ID")
    var subscriptionId: String

    func run() async throws {
        let repo = try ClientProvider.makeProductVersionRepository()
        print(try await execute(repo: repo))
    }

    func execute(
        repo: any ProductVersionRepository,
        affordanceMode: AffordanceMode = .cli
    ) async throws -> String {
        let versions = try await repo.listSubscriptionVersions(subscriptionId: subscriptionId)
        let formatter = OutputFormatter(format: globals.outputFormat, pretty: globals.pretty)
        return try formatter.formatAgentItems(versions, affordanceMode: affordanceMode)
    }
}
