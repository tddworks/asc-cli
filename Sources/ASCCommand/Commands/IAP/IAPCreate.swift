import ArgumentParser
import Domain

struct IAPCreate: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "create",
        abstract: "Create a new in-app purchase"
    )

    @OptionGroup var globals: GlobalOptions

    @Option(name: .long, help: "App ID to create the IAP for")
    var appId: String

    @Option(name: .long, help: "Internal reference name (not displayed to users)")
    var referenceName: String

    @Option(name: .long, help: "Product ID (e.g. com.app.goldcoins)")
    var productId: String

    @Option(name: .long, help: "IAP type: consumable, non-consumable, or non-renewing-subscription")
    var type: String

    func run() async throws {
        let repo = try ClientProvider.makeInAppPurchaseRepository()
        print(try await execute(repo: repo))
    }

    func execute(repo: any InAppPurchaseRepository) async throws -> String {
        guard let iapType = InAppPurchaseType(cliArgument: type) else {
            throw ValidationError("Invalid type '\(type)'. Use: consumable, non-consumable, non-renewing-subscription")
        }
        let item = try await repo.createInAppPurchase(
            appId: appId,
            referenceName: referenceName,
            productId: productId,
            type: iapType
        )
        let formatter = OutputFormatter(format: globals.outputFormat, pretty: globals.pretty)
        return try formatter.formatAgentItems(
            [item],
            headers: ["ID", "Reference Name", "Product ID", "Type", "State"],
            rowMapper: { [$0.id, $0.referenceName, $0.productId, $0.type.displayName, $0.state.rawValue] }
        )
    }
}
