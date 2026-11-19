/// Which compliance a requirement is — the page's COMPLIANCE NAME. It decides
/// what a Yes must carry. Apple's wire spells it as a `formName` code; that code
/// stays here, and an unknown one is kept, never dropped (law 4).
public enum ComplianceKind: Sendable, Equatable, Hashable {
    /// `SECURITYASF395E`. A Yes carries the proof of a completed assessment and its report.
    case securityAssessment
    /// `AIGENERATEFD1DE`. A Yes carries the AIGC filing and any third-party authorization.
    case aiGeneratedContent
    /// A form asc doesn't know yet: listed as Apple names it, never offered `declare`.
    case unrecognized(formName: String)

    public init(formName: String) {
        switch formName {
        case "SECURITYASF395E": self = .securityAssessment
        case "AIGENERATEFD1DE": self = .aiGeneratedContent
        default: self = .unrecognized(formName: formName)
        }
    }

    public var isRecognized: Bool {
        if case .unrecognized = self { return false }
        return true
    }

    public var displayName: String {
        switch self {
        case .securityAssessment: "Security Assessment"
        case .aiGeneratedContent: "AI Generated or Synthetic Content"
        case .unrecognized(let formName): formName
        }
    }

    var jsonValue: String {
        switch self {
        case .securityAssessment: "SECURITY_ASSESSMENT"
        case .aiGeneratedContent: "AI_GENERATED_CONTENT"
        case .unrecognized(let formName): formName
        }
    }
}

extension ComplianceKind: Codable {
    public init(from decoder: any Decoder) throws {
        let value = try decoder.singleValueContainer().decode(String.self)
        switch value {
        case "SECURITY_ASSESSMENT": self = .securityAssessment
        case "AI_GENERATED_CONTENT": self = .aiGeneratedContent
        default: self = ComplianceKind(formName: value)
        }
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(jsonValue)
    }
}
