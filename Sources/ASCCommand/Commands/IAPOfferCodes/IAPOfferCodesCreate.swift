import ArgumentParser
import Domain

struct IAPOfferCodesCreate: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "create",
        abstract: "Create an offer code for an in-app purchase",
        discussion: """
            Per-territory pricing is read-only after creation, so include every territory you
            want the offer code to cover via --price (paid) or --free-territory.
            """
    )

    @OptionGroup var globals: GlobalOptions

    @Option(name: .long, help: "In-app purchase ID")
    var iapId: String

    @Option(name: .long, help: "Offer code name")
    var name: String

    @Option(name: .long, parsing: .singleValue, help: "Customer eligibility: NON_SPENDER, ACTIVE_SPENDER, CHURNED_SPENDER (repeatable)")
    var eligibility: [String]

    @Option(name: .long, parsing: .singleValue,
            help: "Paid price for a territory in `<territory>=<price-point-id>` form (repeatable)")
    var price: [String] = []

    @Option(name: .long, parsing: .singleValue,
            help: "Territory that should redeem the offer for free (repeatable)")
    var freeTerritory: [String] = []

    func run() async throws {
        let repo = try ClientProvider.makeInAppPurchaseOfferCodeRepository()
        print(try await execute(repo: repo))
    }

    func execute(
        repo: any InAppPurchaseOfferCodeRepository,
        affordanceMode: AffordanceMode = .cli
    ) async throws -> String {
        var customerEligibilities: [IAPCustomerEligibility] = []
        for e in eligibility {
            guard let ce = IAPCustomerEligibility(rawValue: e) else {
                throw ValidationError("Invalid eligibility '\(e)'. Use: NON_SPENDER, ACTIVE_SPENDER, CHURNED_SPENDER")
            }
            customerEligibilities.append(ce)
        }
        let prices = try parseOfferCodePrices(paid: price, free: freeTerritory)
        let item = try await repo.createOfferCode(
            iapId: iapId,
            name: name,
            customerEligibilities: customerEligibilities,
            prices: prices
        )
        let formatter = OutputFormatter(format: globals.outputFormat, pretty: globals.pretty)
        return try formatter.formatAgentItems([item], affordanceMode: affordanceMode)
    }
}
