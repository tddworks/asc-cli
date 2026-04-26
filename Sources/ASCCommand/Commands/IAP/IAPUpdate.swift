import ArgumentParser
import Domain

struct IAPUpdate: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "update",
        abstract: "Update an in-app purchase (reference name, review note, family sharable)"
    )

    @OptionGroup var globals: GlobalOptions

    @Option(name: .long, help: "IAP ID")
    var iapId: String

    @Option(name: .long, help: "New reference name")
    var referenceName: String?

    @Option(name: .long, help: "App Review note")
    var reviewNote: String?

    @Flag(name: .long, help: "Mark as Family Sharable")
    var familySharable: Bool = false

    @Flag(name: .long, help: "Mark as not Family Sharable")
    var notFamilySharable: Bool = false

    func run() async throws {
        let repo = try ClientProvider.makeInAppPurchaseRepository()
        print(try await execute(repo: repo))
    }

    func execute(repo: any InAppPurchaseRepository) async throws -> String {
        let isFamilySharable: Bool? = familySharable ? true : (notFamilySharable ? false : nil)
        let item = try await repo.updateInAppPurchase(
            iapId: iapId,
            referenceName: referenceName,
            reviewNote: reviewNote,
            isFamilySharable: isFamilySharable
        )
        let formatter = OutputFormatter(format: globals.outputFormat, pretty: globals.pretty)
        return try formatter.formatAgentItems(
            [item],
            headers: ["ID", "Reference Name", "Product ID", "Type", "State"],
            rowMapper: { [$0.id, $0.referenceName, $0.productId, $0.type.displayName, $0.state.rawValue] }
        )
    }
}
