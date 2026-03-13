public struct BetaAppReviewDetail: Sendable, Equatable, Identifiable {
    public let id: String
    /// Parent app identifier — injected by infrastructure.
    public let appId: String
    public let contactFirstName: String?
    public let contactLastName: String?
    public let contactPhone: String?
    public let contactEmail: String?
    public let demoAccountName: String?
    public let demoAccountPassword: String?
    public let demoAccountRequired: Bool
    public let notes: String?

    public init(
        id: String,
        appId: String,
        contactFirstName: String? = nil,
        contactLastName: String? = nil,
        contactPhone: String? = nil,
        contactEmail: String? = nil,
        demoAccountName: String? = nil,
        demoAccountPassword: String? = nil,
        demoAccountRequired: Bool = false,
        notes: String? = nil
    ) {
        self.id = id
        self.appId = appId
        self.contactFirstName = contactFirstName
        self.contactLastName = contactLastName
        self.contactPhone = contactPhone
        self.contactEmail = contactEmail
        self.demoAccountName = demoAccountName
        self.demoAccountPassword = demoAccountPassword
        self.demoAccountRequired = demoAccountRequired
        self.notes = notes
    }

    public var hasContact: Bool { contactEmail != nil && contactPhone != nil }
    public var demoAccountConfigured: Bool {
        !demoAccountRequired || (demoAccountName != nil && demoAccountPassword != nil)
    }
}

// MARK: - Codable (omit nil optional fields from JSON output)

extension BetaAppReviewDetail: Codable {
    enum CodingKeys: String, CodingKey {
        case id, appId
        case contactFirstName, contactLastName, contactPhone, contactEmail
        case demoAccountName, demoAccountPassword, demoAccountRequired
        case notes
    }

    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        appId = try c.decode(String.self, forKey: .appId)
        contactFirstName = try c.decodeIfPresent(String.self, forKey: .contactFirstName)
        contactLastName = try c.decodeIfPresent(String.self, forKey: .contactLastName)
        contactPhone = try c.decodeIfPresent(String.self, forKey: .contactPhone)
        contactEmail = try c.decodeIfPresent(String.self, forKey: .contactEmail)
        demoAccountName = try c.decodeIfPresent(String.self, forKey: .demoAccountName)
        demoAccountPassword = try c.decodeIfPresent(String.self, forKey: .demoAccountPassword)
        demoAccountRequired = try c.decode(Bool.self, forKey: .demoAccountRequired)
        notes = try c.decodeIfPresent(String.self, forKey: .notes)
    }

    public func encode(to encoder: any Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(appId, forKey: .appId)
        try c.encodeIfPresent(contactFirstName, forKey: .contactFirstName)
        try c.encodeIfPresent(contactLastName, forKey: .contactLastName)
        try c.encodeIfPresent(contactPhone, forKey: .contactPhone)
        try c.encodeIfPresent(contactEmail, forKey: .contactEmail)
        try c.encodeIfPresent(demoAccountName, forKey: .demoAccountName)
        try c.encodeIfPresent(demoAccountPassword, forKey: .demoAccountPassword)
        try c.encode(demoAccountRequired, forKey: .demoAccountRequired)
        try c.encodeIfPresent(notes, forKey: .notes)
    }
}

// MARK: - AffordanceProviding

extension BetaAppReviewDetail: AffordanceProviding {
    public var affordances: [String: String] {
        [
            "getDetail": "asc beta-review detail get --app-id \(appId)",
            "updateDetail": "asc beta-review detail update --detail-id \(id)",
        ]
    }
}

// MARK: - Update

public struct BetaAppReviewDetailUpdate: Sendable, Equatable {
    public let contactFirstName: String?
    public let contactLastName: String?
    public let contactPhone: String?
    public let contactEmail: String?
    public let demoAccountName: String?
    public let demoAccountPassword: String?
    public let demoAccountRequired: Bool?
    public let notes: String?

    public init(
        contactFirstName: String? = nil,
        contactLastName: String? = nil,
        contactPhone: String? = nil,
        contactEmail: String? = nil,
        demoAccountName: String? = nil,
        demoAccountPassword: String? = nil,
        demoAccountRequired: Bool? = nil,
        notes: String? = nil
    ) {
        self.contactFirstName = contactFirstName
        self.contactLastName = contactLastName
        self.contactPhone = contactPhone
        self.contactEmail = contactEmail
        self.demoAccountName = demoAccountName
        self.demoAccountPassword = demoAccountPassword
        self.demoAccountRequired = demoAccountRequired
        self.notes = notes
    }
}