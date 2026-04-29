import ArgumentParser
import Domain

struct SubscriptionGroupLocalizationsUpdate: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "update",
        abstract: "Update a localization for a subscription group"
    )

    @OptionGroup var globals: GlobalOptions

    @Option(name: .long, help: "Localization ID")
    var localizationId: String

    @Option(name: .long, help: "New display name")
    var name: String?

    @Option(name: .long, help: "New custom app name")
    var customAppName: String?

    func run() async throws {
        let repo = try ClientProvider.makeSubscriptionGroupLocalizationRepository()
        print(try await execute(repo: repo))
    }

    func execute(
        repo: any SubscriptionGroupLocalizationRepository,
        affordanceMode: AffordanceMode = .cli
    ) async throws -> String {
        let item = try await repo.updateLocalization(
            localizationId: localizationId,
            name: name,
            customAppName: customAppName
        )
        let formatter = OutputFormatter(format: globals.outputFormat, pretty: globals.pretty)
        return try formatter.formatAgentItems(
            [item],
            headers: ["ID", "Locale", "Name", "Custom App Name"],
            rowMapper: { [$0.id, $0.locale, $0.name ?? "", $0.customAppName ?? ""] },
            affordanceMode: affordanceMode
        )
    }
}
