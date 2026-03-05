public struct ConnectAccount: Sendable, Equatable, Identifiable, Codable {
    public let name: String
    public let keyID: String
    public let issuerID: String
    public let isActive: Bool

    public var id: String { name }

    public init(name: String, keyID: String, issuerID: String, isActive: Bool) {
        self.name = name
        self.keyID = keyID
        self.issuerID = issuerID
        self.isActive = isActive
    }
}

extension ConnectAccount: AffordanceProviding {
    public var affordances: [String: String] {
        var result: [String: String] = [
            "logout": "asc auth logout --name \(name)",
        ]
        if !isActive {
            result["use"] = "asc auth use \(name)"
        }
        return result
    }
}
