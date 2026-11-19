import ArgumentParser
import ASCKit

struct SubscriptionGroupLocalizationsDelete: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "delete",
        abstract: "Delete a subscription group localization"
    )

    @OptionGroup var globals: GlobalOptions

    @Option(name: .long, help: "Localization ID")
    var localizationId: String

    func run() async throws {
        let repo = try ClientProvider.makeSubscriptionGroupLocalizations()
        try await execute(repo: repo)
    }

    func execute(repo: any SubscriptionGroupLocalizations) async throws {
        try await repo.deleteLocalization(localizationId: localizationId)
    }
}
