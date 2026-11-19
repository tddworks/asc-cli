import ArgumentParser
import ASCKit

struct BetaAppLocalizationsDelete: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "delete",
        abstract: "Delete a beta app localization"
    )

    @OptionGroup var globals: GlobalOptions

    @Option(name: .long, help: "Beta app localization ID")
    var localizationId: String

    func run() async throws {
        let repo = try ClientProvider.makeBetaAppLocalizations()
        try await execute(repo: repo)
    }

    func execute(repo: any BetaAppLocalizations) async throws {
        try await repo.deleteBetaAppLocalization(localizationId: localizationId)
    }
}
