import ArgumentParser
import ASCKit

struct ExperimentTreatmentsCreate: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "create",
        abstract: "Add a treatment (up to three per test)"
    )

    @OptionGroup var globals: GlobalOptions

    @Option(name: .long, help: "Experiment ID")
    var experimentId: String

    @Option(name: .long, help: "Treatment name")
    var name: String

    @Option(name: .long, help: "Alternate app icon asset name to test")
    var appIconName: String?

    func run() async throws {
        let repo = try ClientProvider.makeExperimentRepository()
        print(try await execute(repo: repo))
    }

    func execute(
        repo: any ExperimentRepository,
        affordanceMode: AffordanceMode = .cli
    ) async throws -> String {
        let created = try await repo.createTreatment(experimentId: experimentId, name: name, appIconName: appIconName)
        let formatter = OutputFormatter(format: globals.outputFormat, pretty: globals.pretty)
        return try formatter.formatAgentItems([created], affordanceMode: affordanceMode)
    }
}
