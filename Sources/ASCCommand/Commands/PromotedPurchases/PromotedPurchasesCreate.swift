import ArgumentParser
import Domain

struct PromotedPurchasesCreate: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "create",
        abstract: "Create a promoted purchase slot referencing an IAP or subscription"
    )

    @OptionGroup var globals: GlobalOptions

    @Option(name: .long, help: "App ID")
    var appId: String

    @Option(name: .long, help: "IAP ID to promote (mutually exclusive with --subscription-id)")
    var iapId: String?

    @Option(name: .long, help: "Subscription ID to promote (mutually exclusive with --iap-id)")
    var subscriptionId: String?

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
        guard iapId != nil || subscriptionId != nil else {
            throw ValidationError("Either --iap-id or --subscription-id is required")
        }
        if iapId != nil && subscriptionId != nil {
            throw ValidationError("--iap-id and --subscription-id are mutually exclusive")
        }
        let isVisible: Bool = visible ? true : (hidden ? false : true)
        let isEnabled: Bool? = enabled ? true : (disabled ? false : nil)

        let item = try await repo.createPromotedPurchase(
            appId: appId,
            isVisibleForAllUsers: isVisible,
            isEnabled: isEnabled,
            inAppPurchaseId: iapId,
            subscriptionId: subscriptionId
        )
        let formatter = OutputFormatter(format: globals.outputFormat, pretty: globals.pretty)
        return try formatter.formatAgentItems(
            [item],
            headers: PromotedPurchase.tableHeaders,
            rowMapper: { $0.tableRow }
        )
    }
}
