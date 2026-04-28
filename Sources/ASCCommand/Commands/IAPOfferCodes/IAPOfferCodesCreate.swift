import ArgumentParser
import Domain

struct IAPOfferCodesCreate: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "create",
        abstract: "Create an offer code for an in-app purchase"
    )

    @OptionGroup var globals: GlobalOptions

    @Option(name: .long, help: "In-app purchase ID")
    var iapId: String

    @Option(name: .long, help: "Offer code name")
    var name: String

    @Option(name: .long, parsing: .singleValue, help: "Customer eligibility: NON_SPENDER, ACTIVE_SPENDER, CHURNED_SPENDER (repeatable)")
    var eligibility: [String]

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
        let item = try await repo.createOfferCode(
            iapId: iapId,
            name: name,
            customerEligibilities: customerEligibilities
        )
        let formatter = OutputFormatter(format: globals.outputFormat, pretty: globals.pretty)
        return try formatter.formatAgentItems([item], affordanceMode: affordanceMode)
    }
}
