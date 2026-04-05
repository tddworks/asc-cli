import ArgumentParser
import Domain

struct SimulatorsList: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "list",
        abstract: "List available iOS simulators"
    )

    @OptionGroup var globals: GlobalOptions

    @Flag(name: .long, help: "Show only booted simulators")
    var booted: Bool = false

    func run() async throws {
        let repo = ClientProvider.makeSimulatorRepository()
        print(try await execute(repo: repo))
    }

    func execute(repo: any SimulatorRepository, affordanceMode: AffordanceMode = .cli) async throws -> String {
        let filter: SimulatorFilter = booted ? .booted : .available
        let items = try await repo.listSimulators(filter: filter)
        let formatter = OutputFormatter(format: globals.outputFormat, pretty: globals.pretty)
        return try formatter.formatAgentItems(items, affordanceMode: affordanceMode)
    }
}
