import ArgumentParser
import Domain

struct SimulatorsShutdown: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "shutdown",
        abstract: "Shutdown a simulator"
    )

    @Option(name: .long, help: "Simulator UDID")
    var udid: String

    func run() async throws {
        let repo = ClientProvider.makeSimulatorRepository()
        print(try await execute(repo: repo))
    }

    func execute(repo: any SimulatorRepository) async throws -> String {
        try await repo.shutdownSimulator(udid: udid)
        return "Simulator \(udid) shut down successfully."
    }
}
