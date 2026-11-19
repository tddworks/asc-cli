import ArgumentParser
import ASCKit

struct AnalyticsReportsRequest: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "request",
        abstract: "Create an analytics report request for an app"
    )

    @OptionGroup var globals: GlobalOptions

    @Option(name: .long, help: "App ID")
    var appId: String

    @Option(name: .long, help: "Access type: ONE_TIME_SNAPSHOT, ONGOING")
    var accessType: String

    func run() async throws {
        let repo = try ClientProvider.makeAnalyticsReportRepository()
        print(try await execute(repo: repo))
    }

    func execute(repo: any AnalyticsReportRepository) async throws -> String {
        guard let parsed = AnalyticsAccessType(cliArgument: accessType) else {
            throw ValidationError("Invalid access type: \(accessType)")
        }
        let request = try await repo.createRequest(appId: appId, accessType: parsed)
        let formatter = OutputFormatter(format: globals.outputFormat, pretty: globals.pretty)
        return try formatter.formatAgentItems(
            [request],
            headers: ["ID", "App ID", "Access Type"],
            rowMapper: { [$0.id, $0.appId, $0.accessType.rawValue] }
        )
    }
}
