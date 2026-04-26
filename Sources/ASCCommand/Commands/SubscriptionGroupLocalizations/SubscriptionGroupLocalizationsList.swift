import ArgumentParser
import Domain

struct SubscriptionGroupLocalizationsList: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "list",
        abstract: "List localizations for a subscription group"
    )

    @OptionGroup var globals: GlobalOptions

    @Option(name: .long, help: "Subscription group ID")
    var groupId: String

    func run() async throws {
        let repo = try ClientProvider.makeSubscriptionGroupLocalizationRepository()
        print(try await execute(repo: repo))
    }

    func execute(repo: any SubscriptionGroupLocalizationRepository) async throws -> String {
        let items = try await repo.listLocalizations(groupId: groupId)
        let formatter = OutputFormatter(format: globals.outputFormat, pretty: globals.pretty)
        return try formatter.formatAgentItems(items)
    }
}
