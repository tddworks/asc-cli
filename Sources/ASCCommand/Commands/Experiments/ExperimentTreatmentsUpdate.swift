import ArgumentParser
import ASCKit

struct ExperimentTreatmentsUpdate: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "update",
        abstract: "Rename a treatment or change its app icon"
    )

    @OptionGroup var globals: GlobalOptions

    @Option(name: .long, help: "Treatment ID")
    var treatmentId: String

    @Option(name: .long, help: "New treatment name")
    var name: String?

    @Option(name: .long, help: "Alternate app icon asset name")
    var appIconName: String?

    func run() async throws {
        let repo = try ClientProvider.makeExperimentRepository()
        print(try await execute(repo: repo))
    }

    func execute(
        repo: any ExperimentRepository,
        affordanceMode: AffordanceMode = .cli
    ) async throws -> String {
        guard name != nil || appIconName != nil else {
            throw ValidationError("Provide at least one of --name or --app-icon-name")
        }
        let updated = try await repo.updateTreatment(treatmentId: treatmentId, name: name, appIconName: appIconName)
        let formatter = OutputFormatter(format: globals.outputFormat, pretty: globals.pretty)
        return try formatter.formatAgentItems([updated], affordanceMode: affordanceMode)
    }
}
