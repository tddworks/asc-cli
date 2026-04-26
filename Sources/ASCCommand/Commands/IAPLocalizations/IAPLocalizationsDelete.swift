import ArgumentParser
import Domain

struct IAPLocalizationsDelete: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "delete",
        abstract: "Delete a localization for an in-app purchase"
    )

    @OptionGroup var globals: GlobalOptions

    @Option(name: .long, help: "Localization ID")
    var localizationId: String

    func run() async throws {
        let repo = try ClientProvider.makeInAppPurchaseLocalizationRepository()
        try await execute(repo: repo)
    }

    func execute(repo: any InAppPurchaseLocalizationRepository) async throws {
        try await repo.deleteLocalization(localizationId: localizationId)
    }
}
