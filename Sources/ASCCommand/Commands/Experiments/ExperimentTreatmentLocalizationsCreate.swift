import ArgumentParser
import ASCKit

struct ExperimentTreatmentLocalizationsCreate: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "create",
        abstract: "Include a locale in a treatment"
    )

    @OptionGroup var globals: GlobalOptions

    @Option(name: .long, help: "Treatment ID")
    var treatmentId: String

    @Option(name: .long, help: "Locale code (e.g. en-US)")
    var locale: String

    func run() async throws {
        let repo = try ClientProvider.makeExperiments()
        print(try await execute(repo: repo))
    }

    func execute(
        repo: any Experiments,
        affordanceMode: AffordanceMode = .cli
    ) async throws -> String {
        let created = try await repo.createTreatmentLocalization(treatmentId: treatmentId, locale: locale)
        let formatter = OutputFormatter(format: globals.outputFormat, pretty: globals.pretty)
        return try formatter.formatAgentItems([created], affordanceMode: affordanceMode)
    }
}
