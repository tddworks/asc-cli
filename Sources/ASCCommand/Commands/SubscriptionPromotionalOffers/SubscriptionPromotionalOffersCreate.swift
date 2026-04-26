import ArgumentParser
import Domain
import Foundation

struct SubscriptionPromotionalOffersCreate: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "create",
        abstract: "Create a promotional offer with per-territory pricing"
    )

    @OptionGroup var globals: GlobalOptions

    @Option(name: .long, help: "Subscription ID")
    var subscriptionId: String

    @Option(name: .long, help: "Internal name for the offer")
    var name: String

    @Option(name: .long, help: "Offer code (consumer-facing identifier passed to StoreKit)")
    var offerCode: String

    @Option(name: .long, help: "THREE_DAYS, ONE_WEEK, TWO_WEEKS, ONE_MONTH, TWO_MONTHS, THREE_MONTHS, SIX_MONTHS, ONE_YEAR")
    var duration: String

    @Option(name: .long, help: "FREE_TRIAL, PAY_AS_YOU_GO, PAY_UP_FRONT")
    var mode: String

    @Option(name: .long, help: "Number of periods")
    var periods: Int

    @Option(name: .long, parsing: .upToNextOption,
            help: "Per-territory price specs in TERRITORY=PRICE_POINT_ID form, repeatable (e.g. --price USA=pp-1 --price GBR=pp-2)")
    var price: [String] = []

    func run() async throws {
        let repo = try ClientProvider.makeSubscriptionPromotionalOfferRepository()
        print(try await execute(repo: repo))
    }

    func execute(repo: any SubscriptionPromotionalOfferRepository) async throws -> String {
        guard let durationEnum = SubscriptionOfferDuration(rawValue: duration) else {
            throw ValidationError("Invalid duration: \(duration)")
        }
        guard let modeEnum = SubscriptionOfferMode(rawValue: mode) else {
            throw ValidationError("Invalid mode: \(mode)")
        }
        let prices: [PromotionalOfferPriceInput] = try price.map { spec in
            let parts = spec.split(separator: "=", maxSplits: 1).map(String.init)
            guard parts.count == 2, !parts[0].isEmpty, !parts[1].isEmpty else {
                throw ValidationError("Invalid --price spec '\(spec)' — expected TERRITORY=PRICE_POINT_ID")
            }
            return PromotionalOfferPriceInput(territory: parts[0], pricePointId: parts[1])
        }

        let item = try await repo.createPromotionalOffer(
            subscriptionId: subscriptionId,
            name: name,
            offerCode: offerCode,
            duration: durationEnum,
            offerMode: modeEnum,
            numberOfPeriods: periods,
            prices: prices
        )
        let formatter = OutputFormatter(format: globals.outputFormat, pretty: globals.pretty)
        return try formatter.formatAgentItems(
            [item],
            headers: SubscriptionPromotionalOffer.tableHeaders,
            rowMapper: { $0.tableRow }
        )
    }
}
