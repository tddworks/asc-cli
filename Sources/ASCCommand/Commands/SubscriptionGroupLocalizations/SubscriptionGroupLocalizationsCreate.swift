import ArgumentParser
import Domain

struct SubscriptionGroupLocalizationsCreate: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "create",
        abstract: "Create a localization for a subscription group"
    )

    @OptionGroup var globals: GlobalOptions

    @Option(name: .long, help: "Subscription group ID")
    var groupId: String

    @Option(name: .long, help: "Locale code (e.g. en-US, zh-Hans)")
    var locale: String

    @Option(name: .long, help: "Display name shown to users")
    var name: String

    @Option(name: .long, help: "Optional custom app name")
    var customAppName: String?

    func run() async throws {
        let repo = try ClientProvider.makeSubscriptionGroupLocalizationRepository()
        print(try await execute(repo: repo))
    }

    func execute(
        repo: any SubscriptionGroupLocalizationRepository,
        affordanceMode: AffordanceMode = .cli
    ) async throws -> String {
        let item = try await repo.createLocalization(
            groupId: groupId,
            locale: locale,
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
