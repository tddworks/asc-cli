import ArgumentParser
import Domain

extension OfferCodeEnvironment: ExpressibleByArgument {
    public init?(argument: String) {
        switch argument.lowercased() {
        case "production": self = .production
        case "sandbox": self = .sandbox
        default: return nil
        }
    }
}

struct IAPOfferCodeOneTimeCodesCreate: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "create",
        abstract: "Create one-time use codes for an IAP offer code"
    )

    @OptionGroup var globals: GlobalOptions

    @Option(name: .long, help: "Offer code ID")
    var offerCodeId: String

    @Option(name: .long, help: "Number of codes to generate")
    var numberOfCodes: Int

    @Option(name: .long, help: "Expiration date in YYYY-MM-DD format")
    var expirationDate: String

    @Option(name: .long, help: "Redemption environment (production or sandbox)")
    var environment: OfferCodeEnvironment = .production

    func run() async throws {
        let repo = try ClientProvider.makeInAppPurchaseOfferCodeRepository()
        print(try await execute(repo: repo))
    }

    func execute(repo: any InAppPurchaseOfferCodeRepository) async throws -> String {
        let item = try await repo.createOneTimeUseCode(
            offerCodeId: offerCodeId,
            numberOfCodes: numberOfCodes,
            expirationDate: expirationDate,
            environment: environment
        )
        let formatter = OutputFormatter(format: globals.outputFormat, pretty: globals.pretty)
        return try formatter.formatAgentItems([item])
    }
}
