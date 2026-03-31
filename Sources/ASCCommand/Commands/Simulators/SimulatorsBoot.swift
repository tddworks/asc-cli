import ArgumentParser
import Domain

struct SimulatorsBoot: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "boot",
        abstract: "Boot a simulator"
    )

    @Option(name: .long, help: "Simulator UDID")
    var udid: String

    func run() async throws {
        let repo = ClientProvider.makeSimulatorRepository()
        print(try await execute(repo: repo))
    }

    func execute(repo: any SimulatorRepository) async throws -> String {
        try await repo.bootSimulator(udid: udid)
        return "Simulator \(udid) booted successfully."
    }
}
