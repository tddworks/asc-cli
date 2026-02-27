import ArgumentParser
import Domain

struct SubscriptionLocalizationsList: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "list",
        abstract: "List localizations for a subscription"
    )

    @OptionGroup var globals: GlobalOptions

    @Option(name: .long, help: "Subscription ID to list localizations for")
    var subscriptionId: String

    func run() async throws {
        let repo = try ClientProvider.makeSubscriptionLocalizationRepository()
        print(try await execute(repo: repo))
    }

    func execute(repo: any SubscriptionLocalizationRepository) async throws -> String {
        let items = try await repo.listLocalizations(subscriptionId: subscriptionId)
        let formatter = OutputFormatter(format: globals.outputFormat, pretty: globals.pretty)
        return try formatter.formatAgentItems(
            items,
            headers: ["ID", "Locale", "Name", "Description"],
            rowMapper: { [$0.id, $0.locale, $0.name ?? "", $0.description ?? ""] }
        )
    }
}
