import ArgumentParser
import Domain

struct BetaAppLocalizationsDelete: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "delete",
        abstract: "Delete a beta app localization"
    )

    @OptionGroup var globals: GlobalOptions

    @Option(name: .long, help: "Beta app localization ID")
    var localizationId: String

    func run() async throws {
        let repo = try ClientProvider.makeBetaAppLocalizationRepository()
        try await execute(repo: repo)
    }

    func execute(repo: any BetaAppLocalizationRepository) async throws {
        try await repo.deleteBetaAppLocalization(localizationId: localizationId)
    }
}
