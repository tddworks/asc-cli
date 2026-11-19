import ArgumentParser
import ASCKit

struct ExperimentTreatmentLocalizationsDelete: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "delete",
        abstract: "Remove a locale from a treatment"
    )

    @OptionGroup var globals: GlobalOptions

    @Option(name: .long, help: "Treatment localization ID")
    var localizationId: String

    func run() async throws {
        let repo = try ClientProvider.makeExperimentRepository()
        try await execute(repo: repo)
    }

    func execute(repo: any ExperimentRepository) async throws {
        try await repo.deleteTreatmentLocalization(localizationId: localizationId)
    }
}
