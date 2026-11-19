/// What the STATUS column says about a requirement. Only the wire values seen so far
/// are mapped; any other stays `.unrecognized`, shown as Apple sends it (law 4).
public enum ComplianceStatus: Sendable, Equatable, Hashable {
    /// Nobody has answered it (`PENDING_COLLECT`).
    case missingInfo
    /// Apple is checking a Yes (`COLLECTED_VERIFY_PENDING`).
    case pendingVerification
    /// Apple rejected the evidence; the developer corrects and resubmits. Wire value not seen yet.
    case verificationFailed
    /// The app may stay on sale in the region (`COLLECTED_VERIFY_NOT_NECESSARY`, e.g. a No).
    case active
    case unrecognized(wireValue: String)

    public init(wireValue: String) {
        switch wireValue {
        case "PENDING_COLLECT": self = .missingInfo
        case "COLLECTED_VERIFY_PENDING": self = .pendingVerification
        case "COLLECTED_VERIFY_NOT_NECESSARY": self = .active
        default: self = .unrecognized(wireValue: wireValue)
        }
    }

    public var isActive: Bool { self == .active }
    public var isPendingVerification: Bool { self == .pendingVerification }
    /// Missing Info or Verification Failed: the developer has to answer.
    public var needsAction: Bool { self == .missingInfo || self == .verificationFailed }

    public var displayName: String {
        switch self {
        case .missingInfo: "Missing Info"
        case .pendingVerification: "Pending Verification"
        case .verificationFailed: "Verification Failed"
        case .active: "Active"
        case .unrecognized(let wireValue): wireValue
        }
    }

    var jsonValue: String {
        switch self {
        case .missingInfo: "MISSING_INFO"
        case .pendingVerification: "PENDING_VERIFICATION"
        case .verificationFailed: "VERIFICATION_FAILED"
        case .active: "ACTIVE"
        case .unrecognized(let wireValue): wireValue
        }
    }
}

extension ComplianceStatus: Codable {
    public init(from decoder: any Decoder) throws {
        let value = try decoder.singleValueContainer().decode(String.self)
        switch value {
        case "MISSING_INFO": self = .missingInfo
        case "PENDING_VERIFICATION": self = .pendingVerification
        case "VERIFICATION_FAILED": self = .verificationFailed
        case "ACTIVE": self = .active
        default: self = .unrecognized(wireValue: value)
        }
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(jsonValue)
    }
}

/// What Apple still needs before it verifies a declaration.
public enum ComplianceRequiredAction: Sendable, Equatable, Hashable {
    /// Assumed: verified with the app's next submission for review (design, Open question 10).
    case appBinarySubmission
    case unrecognized(wireValue: String)

    public init(wireValue: String) {
        self = wireValue == "APP_BINARY_SUBMISSION" ? .appBinarySubmission : .unrecognized(wireValue: wireValue)
    }

    var wireValue: String {
        switch self {
        case .appBinarySubmission: "APP_BINARY_SUBMISSION"
        case .unrecognized(let wireValue): wireValue
        }
    }
}

extension ComplianceRequiredAction: Codable {
    public init(from decoder: any Decoder) throws {
        self.init(wireValue: try decoder.singleValueContainer().decode(String.self))
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(wireValue)
    }
}
