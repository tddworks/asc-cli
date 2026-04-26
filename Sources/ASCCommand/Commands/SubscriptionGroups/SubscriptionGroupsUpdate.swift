import ArgumentParser
import Domain

struct SubscriptionGroupsUpdate: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "update",
        abstract: "Update a subscription group reference name"
    )

    @OptionGroup var globals: GlobalOptions

    @Option(name: .long, help: "Subscription group ID")
    var groupId: String

    @Option(name: .long, help: "New reference name")
    var referenceName: String

    func run() async throws {
        let repo = try ClientProvider.makeSubscriptionGroupRepository()
        print(try await execute(repo: repo))
    }

    func execute(repo: any SubscriptionGroupRepository) async throws -> String {
        let item = try await repo.updateSubscriptionGroup(groupId: groupId, referenceName: referenceName)
        let formatter = OutputFormatter(format: globals.outputFormat, pretty: globals.pretty)
        return try formatter.formatAgentItems(
            [item],
            headers: ["ID", "Reference Name"],
            rowMapper: { [$0.id, $0.referenceName] }
        )
    }
}
