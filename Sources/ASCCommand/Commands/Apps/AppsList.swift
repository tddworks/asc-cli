import ArgumentParser
import Domain

struct AppsList: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "list",
        abstract: "List all apps"
    )

    @OptionGroup var globals: GlobalOptions

    @Option(name: .long, help: "Maximum number of apps to return")
    var limit: Int?

    func run() async throws {
        let repo = try ClientProvider.makeAppRepository()
        print(try await execute(repo: repo))
    }

    func execute(repo: any AppRepository, affordanceMode: AffordanceMode = .cli) async throws -> String {
        let response = try await repo.listApps(limit: limit)
        let formatter = OutputFormatter(format: globals.outputFormat, pretty: globals.pretty)
        return try formatter.formatAgentItems(response.data, affordanceMode: affordanceMode)
    }
}
