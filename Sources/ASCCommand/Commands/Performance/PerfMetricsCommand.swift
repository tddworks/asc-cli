import ArgumentParser
import Domain
import Foundation

struct PerfMetricsCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "perf-metrics",
        abstract: "Download power and performance metrics for apps and builds",
        subcommands: [PerfMetricsList.self]
    )
}

struct PerfMetricsList: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "list",
        abstract: "List performance metrics for an app or build"
    )

    @OptionGroup var globals: GlobalOptions

    @Option(name: .long, help: "App ID (mutually exclusive with --build-id)")
    var appId: String?

    @Option(name: .long, help: "Build ID (mutually exclusive with --app-id)")
    var buildId: String?

    @Option(name: .long, help: "Filter by metric type: HANG, LAUNCH, MEMORY, DISK, BATTERY, TERMINATION, ANIMATION, STORAGE")
    var metricType: String?

    func run() async throws {
        let repo = try ClientProvider.makePerfMetricsRepository()
        print(try await execute(repo: repo))
    }

    func execute(repo: any PerfMetricsRepository, affordanceMode: AffordanceMode = .cli) async throws -> String {
        let filter = metricType.flatMap { PerformanceMetricCategory(rawValue: $0) }
        let metrics: [PerformanceMetric]

        if let buildId {
            metrics = try await repo.listBuildMetrics(buildId: buildId, metricType: filter)
        } else if let appId {
            metrics = try await repo.listAppMetrics(appId: appId, metricType: filter)
        } else {
            throw ValidationError("Either --app-id or --build-id is required")
        }

        let formatter = OutputFormatter(format: globals.outputFormat, pretty: globals.pretty)
        return try formatter.formatAgentItems(metrics, affordanceMode: affordanceMode)
    }
}
