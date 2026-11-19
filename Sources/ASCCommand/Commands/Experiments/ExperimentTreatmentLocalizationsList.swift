import ArgumentParser
import ASCKit

struct ExperimentTreatmentLocalizationsList: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "list",
        abstract: "List the locales included in a treatment"
    )

    @OptionGroup var globals: GlobalOptions

    @Option(name: .long, help: "Treatment ID")
    var treatmentId: String

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
        let items = try await repo.listTreatmentLocalizations(treatmentId: treatmentId, limit: limit)
        let formatter = OutputFormatter(format: globals.outputFormat, pretty: globals.pretty)
        return try formatter.formatAgentItems(items, affordanceMode: affordanceMode)
    }
}
