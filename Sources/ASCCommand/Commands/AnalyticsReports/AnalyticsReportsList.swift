import ArgumentParser
import Domain

struct AnalyticsReportsList: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "list",
        abstract: "List analytics report requests for an app"
    )

    @OptionGroup var globals: GlobalOptions

    @Option(name: .long, help: "App ID")
    var appId: String

    @Option(name: .long, help: "Filter by access type: ONE_TIME_SNAPSHOT, ONGOING")
    var accessType: String?

    func run() async throws {
        let repo = try ClientProvider.makeAnalyticsReportRepository()
        print(try await execute(repo: repo))
    }

    func execute(repo: any AnalyticsReportRepository) async throws -> String {
        let parsed = accessType.flatMap { AnalyticsAccessType(cliArgument: $0) }
        let requests = try await repo.listRequests(appId: appId, accessType: parsed)
        let formatter = OutputFormatter(format: globals.outputFormat, pretty: globals.pretty)
        return try formatter.formatAgentItems(requests)
    }
}
