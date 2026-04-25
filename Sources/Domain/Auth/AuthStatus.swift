public struct AuthStatus: Sendable, Equatable, Identifiable {
    public let name: String?
    public let keyID: String
    public let issuerID: String
    public let source: CredentialSource
    public let vendorNumber: String?

    public var id: String { name ?? keyID }

    public init(name: String? = nil, keyID: String, issuerID: String, source: CredentialSource, vendorNumber: String? = nil) {
        self.name = name
        self.keyID = keyID
        self.issuerID = issuerID
        self.source = source
        self.vendorNumber = vendorNumber
    }
}

extension AuthStatus: Codable {
    private enum CodingKeys: String, CodingKey {
        case name, keyID, issuerID, source, vendorNumber
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decodeIfPresent(String.self, forKey: .name)
        keyID = try container.decode(String.self, forKey: .keyID)
        issuerID = try container.decode(String.self, forKey: .issuerID)
        source = try container.decode(CredentialSource.self, forKey: .source)
        vendorNumber = try container.decodeIfPresent(String.self, forKey: .vendorNumber)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(name, forKey: .name)
        try container.encode(keyID, forKey: .keyID)
        try container.encode(issuerID, forKey: .issuerID)
        try container.encode(source, forKey: .source)
        try container.encodeIfPresent(vendorNumber, forKey: .vendorNumber)
    }
}

extension AuthStatus: AffordanceProviding {
    public var affordances: [String: String] {
        [
            "check": "asc auth check",
            "list": "asc auth list",
            "login": "asc auth login --key-id <id> --issuer-id <id> --private-key-path <path>",
            "logout": "asc auth logout",
        ]
    }
}

extension AuthStatus: Presentable {
    public static var tableHeaders: [String] {
        ["Name", "Key ID", "Issuer ID", "Source", "Vendor Number"]
    }
    public var tableRow: [String] {
        [name ?? "", keyID, issuerID, source.rawValue, vendorNumber ?? "-"]
    }
}
