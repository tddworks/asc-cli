import ArgumentParser
import Domain

struct SubscriptionGroupsCreate: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "create",
        abstract: "Create a new subscription group"
    )

    @OptionGroup var globals: GlobalOptions

    @Option(name: .long, help: "App ID to create the subscription group for")
    var appId: String

    @Option(name: .long, help: "Internal reference name for the group")
    var referenceName: String

    func run() async throws {
        let repo = try ClientProvider.makeSubscriptionGroupRepository()
        print(try await execute(repo: repo))
    }

    func execute(repo: any SubscriptionGroupRepository) async throws -> String {
        let item = try await repo.createSubscriptionGroup(appId: appId, referenceName: referenceName)
        let formatter = OutputFormatter(format: globals.outputFormat, pretty: globals.pretty)
        return try formatter.formatAgentItems(
            [item],
            headers: ["ID", "Reference Name"],
            rowMapper: { [$0.id, $0.referenceName] }
        )
    }
}
