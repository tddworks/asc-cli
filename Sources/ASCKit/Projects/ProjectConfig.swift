import Foundation

public struct ProjectConfig: Sendable, Equatable, AffordanceProviding {
    public let appId: String
    public let appName: String
    public let bundleId: String
    public let contactFirstName: String?
    public let contactLastName: String?
    public let contactPhone: String?
    public let contactEmail: String?

    public init(
        appId: String,
        appName: String,
        bundleId: String,
        contactFirstName: String? = nil,
        contactLastName: String? = nil,
        contactPhone: String? = nil,
        contactEmail: String? = nil
    ) {
        self.appId = appId
        self.appName = appName
        self.bundleId = bundleId
        self.contactFirstName = contactFirstName
        self.contactLastName = contactLastName
        self.contactPhone = contactPhone
        self.contactEmail = contactEmail
    }

    public var hasReviewContact: Bool { contactEmail != nil && contactPhone != nil }

    public var affordances: [String: String] {
        var cmds = [
            "listVersions":   "asc versions list --app-id \(appId)",
            "listBuilds":     "asc builds list --app-id \(appId)",
            "listAppInfos":   "asc app-infos list --app-id \(appId)",
            "checkReadiness": "asc versions check-readiness --version-id <id>",
        ]
        if hasReviewContact {
            cmds["updateReviewContact"] = "asc init --app-id \(appId) --contact-email ... --contact-phone ..."
        } else {
            cmds["setReviewContact"] = "asc init --app-id \(appId) --contact-email ... --contact-phone ..."
        }
        return cmds
    }
}

// MARK: - Codable (omit nil contact fields from JSON output)

extension ProjectConfig: Codable {
    enum CodingKeys: String, CodingKey {
        case appId, appName, bundleId
        case contactFirstName, contactLastName, contactPhone, contactEmail
    }

    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        appId = try c.decode(String.self, forKey: .appId)
        appName = try c.decode(String.self, forKey: .appName)
        bundleId = try c.decode(String.self, forKey: .bundleId)
        contactFirstName = try c.decodeIfPresent(String.self, forKey: .contactFirstName)
        contactLastName = try c.decodeIfPresent(String.self, forKey: .contactLastName)
        contactPhone = try c.decodeIfPresent(String.self, forKey: .contactPhone)
        contactEmail = try c.decodeIfPresent(String.self, forKey: .contactEmail)
    }

    public func encode(to encoder: any Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(appId, forKey: .appId)
        try c.encode(appName, forKey: .appName)
        try c.encode(bundleId, forKey: .bundleId)
        try c.encodeIfPresent(contactFirstName, forKey: .contactFirstName)
        try c.encodeIfPresent(contactLastName, forKey: .contactLastName)
        try c.encodeIfPresent(contactPhone, forKey: .contactPhone)
        try c.encodeIfPresent(contactEmail, forKey: .contactEmail)
    }
}
