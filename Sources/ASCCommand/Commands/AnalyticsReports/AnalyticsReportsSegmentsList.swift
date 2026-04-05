import ArgumentParser
import Domain

struct AnalyticsReportsSegmentsList: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "segments",
        abstract: "List download segments for a report instance"
    )

    @OptionGroup var globals: GlobalOptions

    @Option(name: .long, help: "Instance ID")
    var instanceId: String

    func run() async throws {
        let repo = try ClientProvider.makeAnalyticsReportRepository()
        print(try await execute(repo: repo))
    }

    func execute(repo: any AnalyticsReportRepository) async throws -> String {
        let segments = try await repo.listSegments(instanceId: instanceId)
        let formatter = OutputFormatter(format: globals.outputFormat, pretty: globals.pretty)
        return try formatter.formatAgentItems(segments)
    }
}
