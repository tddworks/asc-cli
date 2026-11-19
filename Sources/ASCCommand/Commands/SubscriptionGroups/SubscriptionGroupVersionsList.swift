import ArgumentParser
import ASCKit

struct SubscriptionGroupVersionsList: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "list",
        abstract: "List review versions of a subscription group (add a submittable one to a review submission)"
    )

    @OptionGroup var globals: GlobalOptions

    @Option(name: .long, help: "Subscription group ID")
    var groupId: String

    func run() async throws {
        let repo = try ClientProvider.makeProductVersionRepository()
        print(try await execute(repo: repo))
    }

    func execute(
        repo: any ProductVersionRepository,
        affordanceMode: AffordanceMode = .cli
    ) async throws -> String {
        let versions = try await repo.listSubscriptionGroupVersions(groupId: groupId)
        let formatter = OutputFormatter(format: globals.outputFormat, pretty: globals.pretty)
        return try formatter.formatAgentItems(versions, affordanceMode: affordanceMode)
    }
}
