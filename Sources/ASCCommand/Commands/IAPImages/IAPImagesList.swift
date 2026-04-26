import ArgumentParser
import Domain

struct IAPImagesList: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "list",
        abstract: "List promotional images for an in-app purchase"
    )

    @OptionGroup var globals: GlobalOptions

    @Option(name: .long, help: "IAP ID")
    var iapId: String

    func run() async throws {
        let repo = try ClientProvider.makeInAppPurchaseReviewRepository()
        print(try await execute(repo: repo))
    }

    func execute(repo: any InAppPurchaseReviewRepository) async throws -> String {
        let items = try await repo.listImages(iapId: iapId)
        let formatter = OutputFormatter(format: globals.outputFormat, pretty: globals.pretty)
        return try formatter.formatAgentItems(items)
    }
}
