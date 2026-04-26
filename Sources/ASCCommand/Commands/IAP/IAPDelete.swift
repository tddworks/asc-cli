import ArgumentParser
import Domain

struct IAPDelete: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "delete",
        abstract: "Delete an in-app purchase"
    )

    @OptionGroup var globals: GlobalOptions

    @Option(name: .long, help: "IAP ID")
    var iapId: String

    func run() async throws {
        let repo = try ClientProvider.makeInAppPurchaseRepository()
        try await execute(repo: repo)
    }

    func execute(repo: any InAppPurchaseRepository) async throws {
        try await repo.deleteInAppPurchase(iapId: iapId)
    }
}
