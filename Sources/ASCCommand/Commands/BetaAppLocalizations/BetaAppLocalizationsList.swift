import ArgumentParser
import Domain

struct BetaAppLocalizationsList: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "list",
        abstract: "List beta app localizations for an app"
    )

    @OptionGroup var globals: GlobalOptions

    @Option(name: .long, help: "App ID to list beta localizations for")
    var appId: String

    func run() async throws {
        let repo = try ClientProvider.makeBetaAppLocalizationRepository()
        print(try await execute(repo: repo))
    }

    func execute(
        repo: any BetaAppLocalizationRepository,
        affordanceMode: AffordanceMode = .cli
    ) async throws -> String {
        let items = try await repo.listBetaAppLocalizations(appId: appId)
        let formatter = OutputFormatter(format: globals.outputFormat, pretty: globals.pretty)
        return try formatter.formatAgentItems(items, affordanceMode: affordanceMode)
    }
}
