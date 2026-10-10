import ArgumentParser
import Domain
import Foundation

struct PerfOverviewCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "perf-overview",
        abstract: "See an app's Xcode Organizer overview: regressions, metrics vs goals, top hotspots",
        subcommands: [PerfOverviewGet.self]
    )
}

struct PerfOverviewGet: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "get",
        abstract: "Get what regressed in the latest version, each metric against Apple's goal, and the top hang/launch/disk-write hotspots"
    )

    @OptionGroup var globals: GlobalOptions

    @Option(name: .long, help: "App ID")
    var appId: String

    @Option(name: .long, help: "Narrow the overview to one device type (as App Store Connect names it)")
    var deviceType: String?

    func run() async throws {
        let repo = try ClientProvider.makePerfOverviewRepository()
        print(try await execute(repo: repo))
    }

    func execute(repo: any PerfOverviewRepository, affordanceMode: AffordanceMode = .cli) async throws -> String {
        let overview = try await repo.getOverview(appId: appId, deviceType: deviceType)
        let formatter = OutputFormatter(format: globals.outputFormat, pretty: globals.pretty)
        return try formatter.formatAgentItems([overview], affordanceMode: affordanceMode)
    }
}
