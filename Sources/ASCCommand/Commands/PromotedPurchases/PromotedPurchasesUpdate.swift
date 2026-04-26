import ArgumentParser
import Domain

struct PromotedPurchasesUpdate: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "update",
        abstract: "Update a promoted purchase slot's visibility or enabled state"
    )

    @OptionGroup var globals: GlobalOptions

    @Option(name: .long, help: "Promoted purchase ID")
    var promotedId: String

    @Flag(name: .long, help: "Make visible for all users")
    var visible: Bool = false

    @Flag(name: .long, help: "Hide from all users")
    var hidden: Bool = false

    @Flag(name: .long, help: "Enable the slot")
    var enabled: Bool = false

    @Flag(name: .long, help: "Disable the slot")
    var disabled: Bool = false

    func run() async throws {
        let repo = try ClientProvider.makePromotedPurchaseRepository()
        print(try await execute(repo: repo))
    }

    func execute(repo: any PromotedPurchaseRepository) async throws -> String {
        let isVisible: Bool? = visible ? true : (hidden ? false : nil)
        let isEnabled: Bool? = enabled ? true : (disabled ? false : nil)

        let item = try await repo.updatePromotedPurchase(
            promotedId: promotedId,
            isVisibleForAllUsers: isVisible,
            isEnabled: isEnabled
        )
        let formatter = OutputFormatter(format: globals.outputFormat, pretty: globals.pretty)
        return try formatter.formatAgentItems(
            [item],
            headers: PromotedPurchase.tableHeaders,
            rowMapper: { $0.tableRow }
        )
    }
}
