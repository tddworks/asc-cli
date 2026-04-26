import ArgumentParser
import Domain

struct SubscriptionGroupsDelete: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "delete",
        abstract: "Delete a subscription group"
    )

    @OptionGroup var globals: GlobalOptions

    @Option(name: .long, help: "Subscription group ID")
    var groupId: String

    func run() async throws {
        let repo = try ClientProvider.makeSubscriptionGroupRepository()
        try await execute(repo: repo)
    }

    func execute(repo: any SubscriptionGroupRepository) async throws {
        try await repo.deleteSubscriptionGroup(groupId: groupId)
    }
}
