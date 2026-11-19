import ArgumentParser
import ASCKit

struct ExperimentTreatmentsDelete: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "delete",
        abstract: "Delete a treatment"
    )

    @OptionGroup var globals: GlobalOptions

    @Option(name: .long, help: "Treatment ID")
    var treatmentId: String

    func run() async throws {
        let repo = try ClientProvider.makeExperiments()
        try await execute(repo: repo)
    }

    func execute(repo: any Experiments) async throws {
        try await repo.deleteTreatment(treatmentId: treatmentId)
    }
}
