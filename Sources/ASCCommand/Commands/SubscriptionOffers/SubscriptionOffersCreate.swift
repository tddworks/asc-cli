import ArgumentParser
import ASCKit

struct SubscriptionOffersCreate: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "create",
        abstract: "Create an introductory offer for a subscription"
    )

    @OptionGroup var globals: GlobalOptions

    @Option(name: .long, help: "Subscription ID")
    var subscriptionId: String

    @Option(name: .long, help: "Offer duration: THREE_DAYS, ONE_WEEK, TWO_WEEKS, ONE_MONTH, TWO_MONTHS, THREE_MONTHS, SIX_MONTHS, ONE_YEAR")
    var duration: String

    @Option(name: .long, help: "Offer mode: PAY_AS_YOU_GO, PAY_UP_FRONT, FREE_TRIAL")
    var mode: String

    @Option(name: .long, help: "Number of periods")
    var periods: Int

    @Option(name: .long, help: "Territory (e.g. USA) — optional")
    var territory: String?

    @Option(name: .long, help: "Subscription price point ID — required for PAY_AS_YOU_GO and PAY_UP_FRONT")
    var pricePointId: String?

    @Option(name: .long, help: "Start date in YYYY-MM-DD format — optional")
    var startDate: String?

    @Option(name: .long, help: "End date in YYYY-MM-DD format — optional")
    var endDate: String?

    func run() async throws {
        let repo = try ClientProvider.makeSubscriptionIntroductoryOffers()
        print(try await execute(repo: repo))
    }

    func execute(repo: any SubscriptionIntroductoryOffers) async throws -> String {
        guard let offerDuration = SubscriptionOfferDuration(rawValue: duration) else {
            throw ValidationError("Invalid duration '\(duration)'. Use: THREE_DAYS, ONE_WEEK, TWO_WEEKS, ONE_MONTH, TWO_MONTHS, THREE_MONTHS, SIX_MONTHS, ONE_YEAR")
        }
        guard let offerMode = SubscriptionOfferMode(rawValue: mode) else {
            throw ValidationError("Invalid mode '\(mode)'. Use: PAY_AS_YOU_GO, PAY_UP_FRONT, FREE_TRIAL")
        }
        if offerMode.requiresPricePoint && pricePointId == nil {
            throw ValidationError("--price-point-id is required for \(mode) offers")
        }
        let item = try await repo.createIntroductoryOffer(
            subscriptionId: subscriptionId,
            duration: offerDuration,
            offerMode: offerMode,
            numberOfPeriods: periods,
            startDate: startDate,
            endDate: endDate,
            territory: territory,
            pricePointId: pricePointId
        )
        let formatter = OutputFormatter(format: globals.outputFormat, pretty: globals.pretty)
        return try formatter.formatAgentItems(
            [item],
            headers: ["ID", "Duration", "Mode", "Periods", "Territory"],
            rowMapper: { [$0.id, $0.duration.rawValue, $0.offerMode.rawValue, String($0.numberOfPeriods), $0.territory ?? ""] }
        )
    }
}
