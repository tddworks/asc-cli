import ArgumentParser
import Domain

struct WinBackOffersUpdate: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "update",
        abstract: "Update a win-back offer (priority, dates, eligibility)"
    )

    @OptionGroup var globals: GlobalOptions

    @Option(name: .long, help: "Win-back offer ID")
    var offerId: String

    @Option(name: .long, help: "New start date YYYY-MM-DD")
    var startDate: String?

    @Option(name: .long, help: "New end date YYYY-MM-DD")
    var endDate: String?

    @Option(name: .long, help: "New priority: HIGH or NORMAL")
    var priority: String?

    @Option(name: .long, help: "New promotion intent: NOT_PROMOTED or USE_AUTO_GENERATED_ASSETS")
    var promotionIntent: String?

    @Option(name: .long, help: "Months the customer must have paid")
    var paidMonths: Int?

    @Option(name: .long, help: "Minimum months since last subscribed")
    var sinceMin: Int?

    @Option(name: .long, help: "Maximum months since last subscribed")
    var sinceMax: Int?

    @Option(name: .long, help: "Wait between offers in months")
    var waitMonths: Int?

    func run() async throws {
        let repo = try ClientProvider.makeWinBackOfferRepository()
        print(try await execute(repo: repo))
    }

    func execute(repo: any WinBackOfferRepository) async throws -> String {
        let priorityEnum: WinBackOfferPriority? = try priority.map { raw in
            guard let v = WinBackOfferPriority(rawValue: raw) else {
                throw ValidationError("Invalid priority: \(raw)")
            }
            return v
        }
        let intentEnum: WinBackOfferPromotionIntent? = try promotionIntent.map { raw in
            guard let v = WinBackOfferPromotionIntent(rawValue: raw) else {
                throw ValidationError("Invalid promotionIntent: \(raw)")
            }
            return v
        }
        let item = try await repo.updateWinBackOffer(
            offerId: offerId,
            startDate: startDate,
            endDate: endDate,
            priority: priorityEnum,
            promotionIntent: intentEnum,
            paidSubscriptionDurationInMonths: paidMonths,
            timeSinceLastSubscribedMin: sinceMin,
            timeSinceLastSubscribedMax: sinceMax,
            waitBetweenOffersInMonths: waitMonths
        )
        let formatter = OutputFormatter(format: globals.outputFormat, pretty: globals.pretty)
        return try formatter.formatAgentItems(
            [item],
            headers: WinBackOffer.tableHeaders,
            rowMapper: { $0.tableRow }
        )
    }
}
