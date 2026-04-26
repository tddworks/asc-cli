import ArgumentParser
import Domain

struct SubscriptionLocalizationsDelete: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "delete",
        abstract: "Delete a localization for a subscription"
    )

    @OptionGroup var globals: GlobalOptions

    @Option(name: .long, help: "Localization ID")
    var localizationId: String

    func run() async throws {
        let repo = try ClientProvider.makeSubscriptionLocalizationRepository()
        try await execute(repo: repo)
    }

    func execute(repo: any SubscriptionLocalizationRepository) async throws {
        try await repo.deleteLocalization(localizationId: localizationId)
    }
}
