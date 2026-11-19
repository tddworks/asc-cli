import ArgumentParser
import ASCKit

struct IAPDelete: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "delete",
        abstract: "Delete an in-app purchase"
    )

    @OptionGroup var globals: GlobalOptions

    @Option(name: .long, help: "IAP ID")
    var iapId: String

    func run() async throws {
        let repo = try ClientProvider.makeInAppPurchases()
        try await execute(repo: repo)
    }

    func execute(repo: any InAppPurchases) async throws {
        try await repo.deleteInAppPurchase(iapId: iapId)
    }
}
