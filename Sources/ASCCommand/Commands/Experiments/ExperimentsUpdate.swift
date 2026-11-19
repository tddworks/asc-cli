import ArgumentParser
import ASCKit

struct ExperimentsUpdate: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "update",
        abstract: "Rename a test or change its traffic proportion"
    )

    @OptionGroup var globals: GlobalOptions

    @Option(name: .long, help: "Experiment ID")
    var experimentId: String

    @Option(name: .long, help: "New reference name")
    var name: String?

    @Option(name: .long, help: "New traffic proportion (1-100)")
    var trafficProportion: Int?

    func run() async throws {
        let repo = try ClientProvider.makeExperiments()
        print(try await execute(repo: repo))
    }

    func execute(
        repo: any Experiments,
        affordanceMode: AffordanceMode = .cli
    ) async throws -> String {
        guard name != nil || trafficProportion != nil else {
            throw ValidationError("Provide at least one of --name or --traffic-proportion")
        }
        if let trafficProportion, !(1...100).contains(trafficProportion) {
            throw ValidationError("--traffic-proportion must be between 1 and 100")
        }
        let updated = try await repo.updateExperiment(
            experimentId: experimentId, name: name, trafficProportion: trafficProportion, isStarted: nil
        )
        let formatter = OutputFormatter(format: globals.outputFormat, pretty: globals.pretty)
        return try formatter.formatAgentItems([updated], affordanceMode: affordanceMode)
    }
}
