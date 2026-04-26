import ArgumentParser
import Domain

struct PromotedPurchasesDelete: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "delete",
        abstract: "Delete a promoted purchase slot"
    )

    @OptionGroup var globals: GlobalOptions

    @Option(name: .long, help: "Promoted purchase ID")
    var promotedId: String

    func run() async throws {
        let repo = try ClientProvider.makePromotedPurchaseRepository()
        try await execute(repo: repo)
    }

    func execute(repo: any PromotedPurchaseRepository) async throws {
        try await repo.deletePromotedPurchase(promotedId: promotedId)
    }
}
