import ArgumentParser
import Domain
import Foundation

struct DiagnosticsCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "diagnostics",
        abstract: "List diagnostic signatures for a build",
        subcommands: [DiagnosticsList.self]
    )
}

struct DiagnosticsList: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "list",
        abstract: "List diagnostic signatures for a build"
    )

    @OptionGroup var globals: GlobalOptions

    @Option(name: .long, help: "Build ID")
    var buildId: String

    @Option(name: .long, help: "Filter by diagnostic type: DISK_WRITES, HANGS, LAUNCHES")
    var diagnosticType: String?

    func run() async throws {
        let repo = try ClientProvider.makeDiagnosticsRepository()
        print(try await execute(repo: repo))
    }

    func execute(repo: any DiagnosticsRepository, affordanceMode: AffordanceMode = .cli) async throws -> String {
        let filter = diagnosticType.flatMap { DiagnosticType(rawValue: $0) }
        let signatures = try await repo.listSignatures(buildId: buildId, diagnosticType: filter)
        let formatter = OutputFormatter(format: globals.outputFormat, pretty: globals.pretty)
        return try formatter.formatAgentItems(signatures, affordanceMode: affordanceMode)
    }
}
