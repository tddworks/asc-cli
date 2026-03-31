import ArgumentParser

struct SimulatorsCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "simulators",
        abstract: "Manage local iOS simulators",
        subcommands: [
            SimulatorsList.self,
            SimulatorsBoot.self,
            SimulatorsShutdown.self,
            SimulatorsStream.self,
        ]
    )
}
