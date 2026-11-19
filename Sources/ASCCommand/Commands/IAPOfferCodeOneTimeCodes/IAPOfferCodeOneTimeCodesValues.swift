import ArgumentParser
import ASCKit

struct IAPOfferCodeOneTimeCodesValues: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "values",
        abstract: "Fetch the redemption values (CSV) for an IAP one-time code batch"
    )

    @OptionGroup var globals: GlobalOptions

    @Option(name: .long, help: "One-time code batch ID")
    var oneTimeCodeId: String

    func run() async throws {
        let repo = try ClientProvider.makeInAppPurchaseOfferCodes()
        print(try await execute(repo: repo))
    }

    func execute(repo: any InAppPurchaseOfferCodes) async throws -> String {
        try await repo.fetchOneTimeUseCodeValues(oneTimeCodeId: oneTimeCodeId)
    }
}
