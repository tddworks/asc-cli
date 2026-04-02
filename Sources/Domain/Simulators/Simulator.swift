import Foundation

public struct Simulator: Sendable, Equatable, Identifiable, Codable {
    public let id: String
    public let name: String
    public let state: SimulatorState
    public let runtime: String

    public init(
        id: String,
        name: String,
        state: SimulatorState,
        runtime: String
    ) {
        self.id = id
        self.name = name
        self.state = state
        self.runtime = runtime
    }

    public var isBooted: Bool { state.isBooted }

    /// Converts `com.apple.CoreSimulator.SimRuntime.iOS-18-2` → `iOS 18.2`
    public var displayRuntime: String {
        guard runtime.hasPrefix("com.apple.CoreSimulator.SimRuntime."),
              let lastComponent = runtime.split(separator: ".").last else {
            return runtime
        }
        let parts = lastComponent.split(separator: "-", maxSplits: 1)
        guard parts.count == 2 else { return runtime }
        let os = parts[0]
        let version = parts[1].replacingOccurrences(of: "-", with: ".")
        return "\(os) \(version)"
    }

    private enum CodingKeys: String, CodingKey {
        case id, name, state, runtime, isBooted, displayRuntime
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(state, forKey: .state)
        try container.encode(runtime, forKey: .runtime)
        try container.encode(isBooted, forKey: .isBooted)
        try container.encode(displayRuntime, forKey: .displayRuntime)
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        state = try container.decode(SimulatorState.self, forKey: .state)
        runtime = try container.decode(String.self, forKey: .runtime)
    }
}

extension Simulator: AffordanceProviding {
    public var affordances: [String: String] {
        var cmds: [String: String] = [
            "listSimulators": "asc simulators list",
        ]
        if state.isBooted {
            cmds["shutdown"] = "asc simulators shutdown --udid \(id)"
        } else if state == .shutdown {
            cmds["boot"] = "asc simulators boot --udid \(id)"
        }
        return cmds
    }

    public var registryProperties: [String: String] {
        ["isBooted": "\(state.isBooted)"]
    }
}
