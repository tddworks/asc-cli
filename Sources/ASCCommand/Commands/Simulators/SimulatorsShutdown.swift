import ArgumentParser
import ASCKit

struct SimulatorsShutdown: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "shutdown",
        abstract: "Shutdown a simulator"
    )

    @Option(name: .long, help: "Simulator UDID")
    var udid: String

    func run() async throws {
        let repo = ClientProvider.makeSimulators()
        print(try await execute(repo: repo))
    }

    func execute(repo: any Simulators) async throws -> String {
        try await repo.shutdownSimulator(udid: udid)
        return "Simulator \(udid) shut down successfully."
    }
}
