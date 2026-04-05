import ArgumentParser
import Domain

struct IAPLocalizationsList: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "list",
        abstract: "List localizations for an in-app purchase"
    )

    @OptionGroup var globals: GlobalOptions

    @Option(name: .long, help: "IAP ID to list localizations for")
    var iapId: String

    func run() async throws {
        let repo = try ClientProvider.makeInAppPurchaseLocalizationRepository()
        print(try await execute(repo: repo))
    }

    func execute(repo: any InAppPurchaseLocalizationRepository) async throws -> String {
        let items = try await repo.listLocalizations(iapId: iapId)
        let formatter = OutputFormatter(format: globals.outputFormat, pretty: globals.pretty)
        return try formatter.formatAgentItems(items)
    }
}
