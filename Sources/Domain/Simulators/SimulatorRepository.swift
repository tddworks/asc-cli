import Mockable

public enum SimulatorFilter: Sendable, Equatable {
    case all
    case booted
    case available
}

@Mockable
public protocol SimulatorRepository: Sendable {
    func listSimulators(filter: SimulatorFilter) async throws -> [Simulator]
    func bootSimulator(udid: String) async throws
    func shutdownSimulator(udid: String) async throws
}
