import ArgumentParser
import Domain

struct SubscriptionOfferCodesCreate: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "create",
        abstract: "Create an offer code for a subscription",
        discussion: """
            Per-territory pricing is read-only after creation, so include every territory
            via --price (paid) or --free-territory. Use --auto-renew false for a non-renewing
            (one-time) offer; ASC only accepts --mode FREE_TRIAL in that case.
            """
    )

    @OptionGroup var globals: GlobalOptions

    @Option(name: .long, help: "Subscription ID")
    var subscriptionId: String

    @Option(name: .long, help: "Offer code name")
    var name: String

    @Option(name: .long, help: "Offer duration: THREE_DAYS, ONE_WEEK, TWO_WEEKS, ONE_MONTH, TWO_MONTHS, THREE_MONTHS, SIX_MONTHS, ONE_YEAR")
    var duration: String

    @Option(name: .long, help: "Offer mode: PAY_AS_YOU_GO, PAY_UP_FRONT, FREE_TRIAL")
    var mode: String

    @Option(name: .long, help: "Number of periods")
    var periods: Int

    @Option(name: .long, parsing: .singleValue, help: "Customer eligibility: NEW, LAPSED, WIN_BACK, PAID_SUBSCRIBER (repeatable)")
    var eligibility: [String]

    @Option(name: .long, help: "Offer eligibility: STACKABLE, INTRODUCTORY, SUBSCRIPTION_OFFER")
    var offerEligibility: String

    @Option(name: .long, help: "Whether the offer auto-renews after the offer period (default: true). Set --auto-renew false for non-renewing (one-time) offers.")
    var autoRenew: Bool = true

    @Option(name: .long, parsing: .singleValue,
            help: "Paid price for a territory in `<territory>=<price-point-id>` form (repeatable)")
    var price: [String] = []

    @Option(name: .long, parsing: .singleValue,
            help: "Territory that should redeem the offer for free (repeatable)")
    var freeTerritory: [String] = []

    func run() async throws {
        let repo = try ClientProvider.makeSubscriptionOfferCodeRepository()
        print(try await execute(repo: repo))
    }

    func execute(
        repo: any SubscriptionOfferCodeRepository,
        affordanceMode: AffordanceMode = .cli
    ) async throws -> String {
        guard let offerDuration = SubscriptionOfferDuration(rawValue: duration) else {
            throw ValidationError("Invalid duration '\(duration)'. Use: THREE_DAYS, ONE_WEEK, TWO_WEEKS, ONE_MONTH, TWO_MONTHS, THREE_MONTHS, SIX_MONTHS, ONE_YEAR")
        }
        guard let offerMode = SubscriptionOfferMode(rawValue: mode) else {
            throw ValidationError("Invalid mode '\(mode)'. Use: PAY_AS_YOU_GO, PAY_UP_FRONT, FREE_TRIAL")
        }
        var customerEligibilities: [SubscriptionCustomerEligibility] = []
        for e in eligibility {
            guard let ce = SubscriptionCustomerEligibility(rawValue: e) else {
                throw ValidationError("Invalid eligibility '\(e)'. Use: NEW, LAPSED, WIN_BACK, PAID_SUBSCRIBER")
            }
            customerEligibilities.append(ce)
        }
        guard let parsedOfferEligibility = SubscriptionOfferEligibility(rawValue: offerEligibility) else {
            throw ValidationError("Invalid offer eligibility '\(offerEligibility)'. Use: STACKABLE, INTRODUCTORY, SUBSCRIPTION_OFFER")
        }
        let prices = try parseOfferCodePrices(paid: price, free: freeTerritory)
        let item = try await repo.createOfferCode(
            subscriptionId: subscriptionId,
            name: name,
            customerEligibilities: customerEligibilities,
            offerEligibility: parsedOfferEligibility,
            duration: offerDuration,
            offerMode: offerMode,
            numberOfPeriods: periods,
            isAutoRenewEnabled: autoRenew,
            prices: prices
        )
        let formatter = OutputFormatter(format: globals.outputFormat, pretty: globals.pretty)
        return try formatter.formatAgentItems([item], affordanceMode: affordanceMode)
    }
}
