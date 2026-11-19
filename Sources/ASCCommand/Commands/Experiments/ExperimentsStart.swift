import ArgumentParser
import ASCKit

struct ExperimentsStart: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "start",
        abstract: "Start an approved test so it begins serving traffic"
    )

    @OptionGroup var globals: GlobalOptions

    @Option(name: .long, help: "Experiment ID")
    var experimentId: String

    func run() async throws {
        let repo = try ClientProvider.makeExperimentRepository()
        print(try await execute(repo: repo))
    }

    func execute(
        repo: any ExperimentRepository,
        affordanceMode: AffordanceMode = .cli
    ) async throws -> String {
        let updated = try await repo.updateExperiment(
            experimentId: experimentId, name: nil, trafficProportion: nil, isStarted: true
        )
        let formatter = OutputFormatter(format: globals.outputFormat, pretty: globals.pretty)
        return try formatter.formatAgentItems([updated], affordanceMode: affordanceMode)
    }
}
