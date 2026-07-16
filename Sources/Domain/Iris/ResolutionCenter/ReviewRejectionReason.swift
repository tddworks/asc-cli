/// A structured rejection reason attached to a Resolution Center message —
/// the guideline citation behind a rejection (e.g. section "Performance",
/// code "2.1"). Sourced from the iris `reviewRejections` resource.
public struct ReviewRejectionReason: Sendable, Equatable, Identifiable, Codable {
    public let id: String
    public let section: String?
    public let descriptionText: String?
    public let code: String?

    public init(
        id: String,
        section: String? = nil,
        descriptionText: String? = nil,
        code: String? = nil
    ) {
        self.id = id
        self.section = section
        self.descriptionText = descriptionText
        self.code = code
    }
}

// MARK: - Codable (omit nil optional fields from JSON output)

extension ReviewRejectionReason {
    enum CodingKeys: String, CodingKey {
        case id, section, descriptionText, code
    }

    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        section = try c.decodeIfPresent(String.self, forKey: .section)
        descriptionText = try c.decodeIfPresent(String.self, forKey: .descriptionText)
        code = try c.decodeIfPresent(String.self, forKey: .code)
    }

    public func encode(to encoder: any Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encodeIfPresent(section, forKey: .section)
        try c.encodeIfPresent(descriptionText, forKey: .descriptionText)
        try c.encodeIfPresent(code, forKey: .code)
    }
}
