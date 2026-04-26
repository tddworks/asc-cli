import ArgumentParser
import Domain

struct WinBackOffersCreate: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "create",
        abstract: "Create a win-back offer with eligibility rules and per-territory pricing"
    )

    @OptionGroup var globals: GlobalOptions

    @Option(name: .long, help: "Subscription ID")
    var subscriptionId: String

    @Option(name: .long, help: "Internal name")
    var referenceName: String

    @Option(name: .long, help: "Offer ID (consumer-facing identifier)")
    var offerId: String

    @Option(name: .long, help: "Duration: THREE_DAYS, ONE_WEEK, TWO_WEEKS, ONE_MONTH, TWO_MONTHS, THREE_MONTHS, SIX_MONTHS, ONE_YEAR")
    var duration: String

    @Option(name: .long, help: "Mode: FREE_TRIAL, PAY_AS_YOU_GO, PAY_UP_FRONT")
    var mode: String

    @Option(name: .long, help: "Number of periods")
    var periods: Int

    @Option(name: .long, help: "Months the customer must have paid before they qualify")
    var paidMonths: Int

    @Option(name: .long, help: "Minimum months since last subscribed")
    var sinceMin: Int

    @Option(name: .long, help: "Maximum months since last subscribed")
    var sinceMax: Int

    @Option(name: .long, help: "Optional minimum wait between offers in months")
    var waitMonths: Int?

    @Option(name: .long, help: "Start date YYYY-MM-DD")
    var startDate: String

    @Option(name: .long, help: "Optional end date YYYY-MM-DD")
    var endDate: String?

    @Option(name: .long, help: "Priority: HIGH or NORMAL")
    var priority: String

    @Option(name: .long, help: "Optional promotion intent: NOT_PROMOTED or USE_AUTO_GENERATED_ASSETS")
    var promotionIntent: String?

    @Option(name: .long, parsing: .upToNextOption,
            help: "Per-territory price specs in TERRITORY=PRICE_POINT_ID form, repeatable")
    var price: [String] = []

    func run() async throws {
        let repo = try ClientProvider.makeWinBackOfferRepository()
        print(try await execute(repo: repo))
    }

    func execute(repo: any WinBackOfferRepository) async throws -> String {
        guard let durationEnum = SubscriptionOfferDuration(rawValue: duration) else {
            throw ValidationError("Invalid duration: \(duration)")
        }
        guard let modeEnum = SubscriptionOfferMode(rawValue: mode) else {
            throw ValidationError("Invalid mode: \(mode)")
        }
        guard let priorityEnum = WinBackOfferPriority(rawValue: priority) else {
            throw ValidationError("Invalid priority: \(priority)")
        }
        let promotionIntentEnum: WinBackOfferPromotionIntent? = try promotionIntent.map { intentRaw in
            guard let v = WinBackOfferPromotionIntent(rawValue: intentRaw) else {
                throw ValidationError("Invalid promotionIntent: \(intentRaw)")
            }
            return v
        }
        let prices: [WinBackOfferPriceInput] = try price.map { spec in
            let parts = spec.split(separator: "=", maxSplits: 1).map(String.init)
            guard parts.count == 2, !parts[0].isEmpty, !parts[1].isEmpty else {
                throw ValidationError("Invalid --price spec '\(spec)' — expected TERRITORY=PRICE_POINT_ID")
            }
            return WinBackOfferPriceInput(territory: parts[0], pricePointId: parts[1])
        }

        let item = try await repo.createWinBackOffer(
            subscriptionId: subscriptionId,
            referenceName: referenceName,
            offerId: offerId,
            duration: durationEnum,
            offerMode: modeEnum,
            periodCount: periods,
            paidSubscriptionDurationInMonths: paidMonths,
            timeSinceLastSubscribedMin: sinceMin,
            timeSinceLastSubscribedMax: sinceMax,
            waitBetweenOffersInMonths: waitMonths,
            startDate: startDate,
            endDate: endDate,
            priority: priorityEnum,
            promotionIntent: promotionIntentEnum,
            prices: prices
        )
        let formatter = OutputFormatter(format: globals.outputFormat, pretty: globals.pretty)
        return try formatter.formatAgentItems(
            [item],
            headers: WinBackOffer.tableHeaders,
            rowMapper: { $0.tableRow }
        )
    }
}
