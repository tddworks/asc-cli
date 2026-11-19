import ArgumentParser
import ASCKit

struct SubscriptionOfferCodeOneTimeCodesValues: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "values",
        abstract: "Fetch the redemption values (CSV) for a subscription one-time code batch"
    )

    @OptionGroup var globals: GlobalOptions

    @Option(name: .long, help: "One-time code batch ID")
    var oneTimeCodeId: String

    func run() async throws {
        let repo = try ClientProvider.makeSubscriptionOfferCodes()
        print(try await execute(repo: repo))
    }

    func execute(repo: any SubscriptionOfferCodes) async throws -> String {
        try await repo.fetchOneTimeUseCodeValues(oneTimeCodeId: oneTimeCodeId)
    }
}
