import ArgumentParser
import ASCKit

struct ExperimentTreatmentsList: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "list",
        abstract: "List treatments of a test"
    )

    @OptionGroup var globals: GlobalOptions

    @Option(name: .long, help: "Experiment ID")
    var experimentId: String

    @Option(name: .long, help: "Max results")
    var limit: Int?

    func run() async throws {
        let repo = try ClientProvider.makeExperimentRepository()
        print(try await execute(repo: repo))
    }

    func execute(
        repo: any ExperimentRepository,
        affordanceMode: AffordanceMode = .cli
    ) async throws -> String {
        let response = try await repo.listTreatments(experimentId: experimentId, limit: limit)
        let formatter = OutputFormatter(format: globals.outputFormat, pretty: globals.pretty)
        return try formatter.formatAgentItems(response.data, affordanceMode: affordanceMode)
    }
}
