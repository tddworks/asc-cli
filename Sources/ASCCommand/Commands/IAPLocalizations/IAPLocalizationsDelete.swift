import ArgumentParser
import ASCKit

struct IAPLocalizationsDelete: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "delete",
        abstract: "Delete a localization for an in-app purchase"
    )

    @OptionGroup var globals: GlobalOptions

    @Option(name: .long, help: "Localization ID")
    var localizationId: String

    func run() async throws {
        let repo = try ClientProvider.makeInAppPurchaseLocalizations()
        try await execute(repo: repo)
    }

    func execute(repo: any InAppPurchaseLocalizations) async throws {
        try await repo.deleteLocalization(localizationId: localizationId)
    }
}
