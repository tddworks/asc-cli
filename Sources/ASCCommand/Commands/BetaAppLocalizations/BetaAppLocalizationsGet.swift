import ArgumentParser
import Domain

struct BetaAppLocalizationsGet: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "get",
        abstract: "Get a single beta app localization by ID"
    )

    @OptionGroup var globals: GlobalOptions

    @Option(name: .long, help: "Beta app localization ID")
    var localizationId: String

    func run() async throws {
        let repo = try ClientProvider.makeBetaAppLocalizationRepository()
        print(try await execute(repo: repo))
    }

    func execute(
        repo: any BetaAppLocalizationRepository,
        affordanceMode: AffordanceMode = .cli
    ) async throws -> String {
        let item = try await repo.getBetaAppLocalization(localizationId: localizationId)
        let formatter = OutputFormatter(format: globals.outputFormat, pretty: globals.pretty)
        return try formatter.formatAgentItems([item], affordanceMode: affordanceMode)
    }
}
