import Domain
import Foundation

public struct SimctlSimulatorRepository: SimulatorRepository, @unchecked Sendable {
    private let shellRunner: ShellRunner

    public init(shellRunner: ShellRunner = SystemShellRunner()) {
        self.shellRunner = shellRunner
    }

    public func listSimulators(filter: SimulatorFilter) async throws -> [Simulator] {
        let arguments: [String]
        switch filter {
        case .booted:
            arguments = ["simctl", "list", "devices", "booted", "--json"]
        case .available:
            arguments = ["simctl", "list", "devices", "available", "--json"]
        case .all:
            arguments = ["simctl", "list", "devices", "--json"]
        }

        let output = try await shellRunner.run(command: "xcrun", arguments: arguments, environment: nil)
        guard let data = output.data(using: .utf8) else { return [] }
        let decoded = try JSONDecoder().decode(SimctlDeviceList.self, from: data)

        return decoded.devices
            .filter { runtime, _ in runtime.contains("iOS") }
            .flatMap { runtime, devices in
                devices.compactMap { device -> Simulator? in
                    guard let state = SimulatorState(rawValue: device.state) else { return nil }
                    return Simulator(
                        id: device.udid,
                        name: device.name,
                        state: state,
                        runtime: runtime
                    )
                }
            }
            .sorted { lhs, rhs in
                if lhs.isBooted != rhs.isBooted { return lhs.isBooted }
                return lhs.name < rhs.name
            }
    }

    public func bootSimulator(udid: String) async throws {
        _ = try await shellRunner.run(command: "xcrun", arguments: ["simctl", "boot", udid], environment: nil)
    }

    public func shutdownSimulator(udid: String) async throws {
        _ = try await shellRunner.run(command: "xcrun", arguments: ["simctl", "shutdown", udid], environment: nil)
    }
}

// MARK: - simctl JSON Models

private struct SimctlDeviceList: Decodable {
    let devices: [String: [SimctlDevice]]
}

private struct SimctlDevice: Decodable {
    let udid: String
    let name: String
    let state: String
}
