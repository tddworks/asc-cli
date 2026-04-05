import ArgumentParser
import Domain

struct AnalyticsReportsReportsList: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "reports",
        abstract: "List available reports for a request"
    )

    @OptionGroup var globals: GlobalOptions

    @Option(name: .long, help: "Request ID")
    var requestId: String

    @Option(name: .long, help: "Filter by category: APP_USAGE, APP_STORE_ENGAGEMENT, COMMERCE, FRAMEWORK_USAGE, PERFORMANCE")
    var category: String?

    func run() async throws {
        let repo = try ClientProvider.makeAnalyticsReportRepository()
        print(try await execute(repo: repo))
    }

    func execute(repo: any AnalyticsReportRepository) async throws -> String {
        let parsed = category.flatMap { AnalyticsCategory(cliArgument: $0) }
        let reports = try await repo.listReports(requestId: requestId, category: parsed)
        let formatter = OutputFormatter(format: globals.outputFormat, pretty: globals.pretty)
        return try formatter.formatAgentItems(reports)
    }
}
