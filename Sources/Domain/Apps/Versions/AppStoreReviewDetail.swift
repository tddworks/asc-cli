public struct AppStoreReviewDetail: Sendable, Equatable, Identifiable {
    public let id: String
    /// Parent version identifier — always present so agents can correlate responses.
    public let versionId: String
    public let contactFirstName: String?
    public let contactLastName: String?
    public let contactPhone: String?
    public let contactEmail: String?
    public let demoAccountRequired: Bool
    public let demoAccountName: String?
    public let demoAccountPassword: String?
    public let notes: String?

    public init(
        id: String,
        versionId: String,
        contactFirstName: String? = nil,
        contactLastName: String? = nil,
        contactPhone: String? = nil,
        contactEmail: String? = nil,
        demoAccountRequired: Bool = false,
        demoAccountName: String? = nil,
        demoAccountPassword: String? = nil,
        notes: String? = nil
    ) {
        self.id = id
        self.versionId = versionId
        self.contactFirstName = contactFirstName
        self.contactLastName = contactLastName
        self.contactPhone = contactPhone
        self.contactEmail = contactEmail
        self.demoAccountRequired = demoAccountRequired
        self.demoAccountName = demoAccountName
        self.demoAccountPassword = demoAccountPassword
        self.notes = notes
    }

    public var hasContact: Bool { contactEmail != nil && contactPhone != nil }
    public var demoAccountConfigured: Bool {
        !demoAccountRequired || (demoAccountName != nil && demoAccountPassword != nil)
    }
}

// MARK: - Codable (omit nil optional fields from JSON output)

extension AppStoreReviewDetail: Codable {
    enum CodingKeys: String, CodingKey {
        case id, versionId
        case contactFirstName, contactLastName, contactPhone, contactEmail
        case demoAccountRequired, demoAccountName, demoAccountPassword
        case notes
    }

    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        versionId = try c.decode(String.self, forKey: .versionId)
        contactFirstName = try c.decodeIfPresent(String.self, forKey: .contactFirstName)
        contactLastName = try c.decodeIfPresent(String.self, forKey: .contactLastName)
        contactPhone = try c.decodeIfPresent(String.self, forKey: .contactPhone)
        contactEmail = try c.decodeIfPresent(String.self, forKey: .contactEmail)
        demoAccountRequired = try c.decode(Bool.self, forKey: .demoAccountRequired)
        demoAccountName = try c.decodeIfPresent(String.self, forKey: .demoAccountName)
        demoAccountPassword = try c.decodeIfPresent(String.self, forKey: .demoAccountPassword)
        notes = try c.decodeIfPresent(String.self, forKey: .notes)
    }

    public func encode(to encoder: any Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(versionId, forKey: .versionId)
        try c.encodeIfPresent(contactFirstName, forKey: .contactFirstName)
        try c.encodeIfPresent(contactLastName, forKey: .contactLastName)
        try c.encodeIfPresent(contactPhone, forKey: .contactPhone)
        try c.encodeIfPresent(contactEmail, forKey: .contactEmail)
        try c.encode(demoAccountRequired, forKey: .demoAccountRequired)
        try c.encodeIfPresent(demoAccountName, forKey: .demoAccountName)
        try c.encodeIfPresent(demoAccountPassword, forKey: .demoAccountPassword)
        try c.encodeIfPresent(notes, forKey: .notes)
    }
}

// MARK: - AffordanceProviding

extension AppStoreReviewDetail: AffordanceProviding {
    public var affordances: [String: String] {
        [
            "getReviewDetail": "asc version-review-detail get --version-id \(versionId)",
            "updateReviewDetail": "asc version-review-detail update --version-id \(versionId)",
        ]
    }
}
