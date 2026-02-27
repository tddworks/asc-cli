import ArgumentParser
import Domain

struct IAPLocalizationsCreate: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "create",
        abstract: "Create a localization for an in-app purchase"
    )

    @OptionGroup var globals: GlobalOptions

    @Option(name: .long, help: "IAP ID to create localization for")
    var iapId: String

    @Option(name: .long, help: "Locale code (e.g. en-US, zh-Hans)")
    var locale: String

    @Option(name: .long, help: "Display name shown to users")
    var name: String

    @Option(name: .long, help: "Optional description shown to users")
    var description: String?

    func run() async throws {
        let repo = try ClientProvider.makeInAppPurchaseLocalizationRepository()
        print(try await execute(repo: repo))
    }

    func execute(repo: any InAppPurchaseLocalizationRepository) async throws -> String {
        let item = try await repo.createLocalization(
            iapId: iapId,
            locale: locale,
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
