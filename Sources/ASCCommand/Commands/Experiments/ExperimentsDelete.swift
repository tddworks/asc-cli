import ArgumentParser
import ASCKit

struct ExperimentsDelete: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "delete",
        abstract: "Delete a product page optimization test"
    )

    @OptionGroup var globals: GlobalOptions

    @Option(name: .long, help: "Experiment ID")
    var experimentId: String

    func run() async throws {
        let repo = try ClientProvider.makeExperiments()
        try await execute(repo: repo)
    }

    func execute(repo: any Experiments) async throws {
        try await repo.deleteExperiment(experimentId: experimentId)
    }
}
