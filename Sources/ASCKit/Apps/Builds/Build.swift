import Foundation

public struct Build: Sendable, Equatable, Identifiable {
    public let id: String
    public let version: String
    public let uploadedDate: Date?
    public let expirationDate: Date?
    public let expired: Bool
    public let processingState: ProcessingState
    public let buildNumber: String?
    public let platform: BuildUploadPlatform?
    /// Apple's export-compliance answer (Info.plist `ITSAppUsesNonExemptEncryption`).
    /// `nil` means "not yet answered" — Apple blocks TestFlight external testing in that state.
    public let usesNonExemptEncryption: Bool?

    public init(
        id: String,
        version: String,
        uploadedDate: Date? = nil,
        expirationDate: Date? = nil,
        expired: Bool = false,
        processingState: ProcessingState = .valid,
        buildNumber: String? = nil,
        platform: BuildUploadPlatform? = nil,
        usesNonExemptEncryption: Bool? = nil
    ) {
        self.id = id
        self.version = version
        self.uploadedDate = uploadedDate
        self.expirationDate = expirationDate
        self.expired = expired
        self.processingState = processingState
        self.buildNumber = buildNumber
        self.platform = platform
        self.usesNonExemptEncryption = usesNonExemptEncryption
    }

    public var isUsable: Bool {
        !expired && processingState == .valid
    }

    /// `true` when Apple has not yet been told whether the build uses non-exempt encryption
    /// (Info.plist `ITSAppUsesNonExemptEncryption` missing). TestFlight external testing
    /// is blocked while this is `true`.
    public var isMissingEncryptionCompliance: Bool {
        usesNonExemptEncryption == nil
    }

    public enum ProcessingState: String, Sendable, Codable {
        case processing = "PROCESSING"
        case failed = "FAILED"
        case invalid = "INVALID"
        case valid = "VALID"
    }
}

extension Build: Codable {
    enum CodingKeys: String, CodingKey {
        case id, version, uploadedDate, expirationDate, expired, processingState
        case buildNumber, platform, usesNonExemptEncryption
    }

    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        version = try c.decode(String.self, forKey: .version)
        uploadedDate = try c.decodeIfPresent(Date.self, forKey: .uploadedDate)
        expirationDate = try c.decodeIfPresent(Date.self, forKey: .expirationDate)
        expired = try c.decode(Bool.self, forKey: .expired)
        processingState = try c.decode(ProcessingState.self, forKey: .processingState)
        buildNumber = try c.decodeIfPresent(String.self, forKey: .buildNumber)
        platform = try c.decodeIfPresent(BuildUploadPlatform.self, forKey: .platform)
        usesNonExemptEncryption = try c.decodeIfPresent(Bool.self, forKey: .usesNonExemptEncryption)
    }

    public func encode(to encoder: any Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(version, forKey: .version)
        try c.encodeIfPresent(uploadedDate, forKey: .uploadedDate)
        try c.encodeIfPresent(expirationDate, forKey: .expirationDate)
        try c.encode(expired, forKey: .expired)
        try c.encode(processingState, forKey: .processingState)
        try c.encodeIfPresent(buildNumber, forKey: .buildNumber)
        try c.encodeIfPresent(platform, forKey: .platform)
        try c.encodeIfPresent(usesNonExemptEncryption, forKey: .usesNonExemptEncryption)
    }
}

extension Build: Presentable {
    public static var tableHeaders: [String] {
        ["ID", "Version", "Build Number", "Platform", "State", "Expired", "Encryption"]
    }
    public var tableRow: [String] {
        let encryption: String
        switch usesNonExemptEncryption {
        case .some(true): encryption = "uses"
        case .some(false): encryption = "exempt"
        case .none: encryption = "missing"
        }
        return [
            id,
            version,
            buildNumber ?? "-",
            platform?.rawValue ?? "-",
            processingState.rawValue,
            expired ? "Yes" : "No",
            encryption,
        ]
    }
}

extension Build: AffordanceProviding {
    public var affordances: [String: String] {
        guard isUsable else { return [:] }
        var items: [String: String] = [
            "addToTestFlight": "asc builds add-beta-group --build-id \(id) --beta-group-id <beta-group-id>",
            "updateBetaNotes": "asc builds update-beta-notes --build-id \(id) --locale en-US --notes <notes>",
        ]
        if isMissingEncryptionCompliance {
            items["setEncryptionCompliance"] = "asc builds set-encryption-compliance --build-id \(id) --uses-non-exempt-encryption <true|false>"
        }
        return items
    }
}
