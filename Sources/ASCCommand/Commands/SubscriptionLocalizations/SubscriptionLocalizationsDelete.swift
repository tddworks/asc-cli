import ArgumentParser
import ASCKit

struct SubscriptionLocalizationsDelete: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "delete",
        abstract: "Delete a localization for a subscription"
    )

    @OptionGroup var globals: GlobalOptions

    @Option(name: .long, help: "Localization ID")
    var localizationId: String

    func run() async throws {
        let repo = try ClientProvider.makeSubscriptionLocalizations()
        try await execute(repo: repo)
    }

    func execute(repo: any SubscriptionLocalizations) async throws {
        try await repo.deleteLocalization(localizationId: localizationId)
    }
}
