import ArgumentParser
import Domain

struct IAPOfferCodeOneTimeCodesValues: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "values",
        abstract: "Fetch the redemption values (CSV) for an IAP one-time code batch"
    )

    @OptionGroup var globals: GlobalOptions

    @Option(name: .long, help: "One-time code batch ID")
    var oneTimeCodeId: String

    func run() async throws {
        let repo = try ClientProvider.makeInAppPurchaseOfferCodeRepository()
        print(try await execute(repo: repo))
    }

    func execute(repo: any InAppPurchaseOfferCodeRepository) async throws -> String {
        try await repo.fetchOneTimeUseCodeValues(oneTimeCodeId: oneTimeCodeId)
    }
}
