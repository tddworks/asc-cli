public enum SimulatorState: String, Sendable, Equatable, Codable, CaseIterable {
    case booted = "Booted"
    case shutdown = "Shutdown"
    case shuttingDown = "Shutting Down"
    case creating = "Creating"

    public var isBooted: Bool { self == .booted }
    public var isAvailable: Bool { self == .booted || self == .shutdown }
}
