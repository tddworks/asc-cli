import ArgumentParser
import Domain

struct AnalyticsReportsInstancesList: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "instances",
        abstract: "List report instances for a report"
    )

    @OptionGroup var globals: GlobalOptions

    @Option(name: .long, help: "Report ID")
    var reportId: String

    @Option(name: .long, help: "Filter by granularity: DAILY, WEEKLY, MONTHLY")
    var granularity: String?

    func run() async throws {
        let repo = try ClientProvider.makeAnalyticsReportRepository()
        print(try await execute(repo: repo))
    }

    func execute(repo: any AnalyticsReportRepository) async throws -> String {
        let parsed = granularity.flatMap { AnalyticsGranularity(cliArgument: $0) }
        let instances = try await repo.listInstances(reportId: reportId, granularity: parsed)
        let formatter = OutputFormatter(format: globals.outputFormat, pretty: globals.pretty)
        return try formatter.formatAgentItems(instances)
    }
}
