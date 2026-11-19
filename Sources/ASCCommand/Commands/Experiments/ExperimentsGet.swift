import ArgumentParser
import ASCKit

struct ExperimentsGet: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "get",
        abstract: "Get a product page optimization test"
    )

    @OptionGroup var globals: GlobalOptions

    @Option(name: .long, help: "Experiment ID")
    var experimentId: String

    func run() async throws {
        let repo = try ClientProvider.makeExperiments()
        print(try await execute(repo: repo))
    }

    func execute(
        repo: any Experiments,
        affordanceMode: AffordanceMode = .cli
    ) async throws -> String {
        let experiment = try await repo.getExperiment(experimentId: experimentId)
        let formatter = OutputFormatter(format: globals.outputFormat, pretty: globals.pretty)
        return try formatter.formatAgentItems([experiment], affordanceMode: affordanceMode)
    }
}
