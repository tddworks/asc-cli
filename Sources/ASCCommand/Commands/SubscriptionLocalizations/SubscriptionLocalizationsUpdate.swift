import ArgumentParser
import Domain

struct SubscriptionLocalizationsUpdate: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "update",
        abstract: "Update a localization for a subscription"
    )

    @OptionGroup var globals: GlobalOptions

    @Option(name: .long, help: "Localization ID")
    var localizationId: String

    @Option(name: .long, help: "New display name")
    var name: String?

    @Option(name: .long, help: "New description")
    var description: String?

    func run() async throws {
        let repo = try ClientProvider.makeSubscriptionLocalizationRepository()
        print(try await execute(repo: repo))
    }

    func execute(repo: any SubscriptionLocalizationRepository) async throws -> String {
        let item = try await repo.updateLocalization(
            localizationId: localizationId,
            name: name,
            description: description
        )
        let formatter = OutputFormatter(format: globals.outputFormat, pretty: globals.pretty)
        return try formatter.formatAgentItems(
            [item],
            headers: ["ID", "Locale", "Name", "Description"],
            rowMapper: { [$0.id, $0.locale, $0.name ?? "", $0.description ?? ""] }
        )
    }
}
