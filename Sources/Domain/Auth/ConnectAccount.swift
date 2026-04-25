public struct ConnectAccount: Sendable, Equatable, Identifiable {
    public let name: String
    public let keyID: String
    public let issuerID: String
    public let isActive: Bool
    public let vendorNumber: String?

    public var id: String { name }

    public init(name: String, keyID: String, issuerID: String, isActive: Bool, vendorNumber: String? = nil) {
        self.name = name
        self.keyID = keyID
        self.issuerID = issuerID
        self.isActive = isActive
        self.vendorNumber = vendorNumber
    }
}

extension ConnectAccount: Codable {
    private enum CodingKeys: String, CodingKey {
        case name, keyID, issuerID, isActive, vendorNumber
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decode(String.self, forKey: .name)
        keyID = try container.decode(String.self, forKey: .keyID)
        issuerID = try container.decode(String.self, forKey: .issuerID)
        isActive = try container.decode(Bool.self, forKey: .isActive)
        vendorNumber = try container.decodeIfPresent(String.self, forKey: .vendorNumber)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        try container.encode(keyID, forKey: .keyID)
        try container.encode(issuerID, forKey: .issuerID)
        try container.encode(isActive, forKey: .isActive)
        try container.encodeIfPresent(vendorNumber, forKey: .vendorNumber)
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

extension ConnectAccount: Presentable {
    public static var tableHeaders: [String] {
        ["Name", "Key ID", "Issuer ID", "Active", "Vendor Number"]
    }
    public var tableRow: [String] {
        [name, keyID, issuerID, isActive ? "*" : "", vendorNumber ?? "-"]
    }
}
