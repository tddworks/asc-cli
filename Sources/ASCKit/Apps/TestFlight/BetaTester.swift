public struct BetaTester: Sendable, Equatable, Identifiable {
    public let id: String
    public let groupId: String
    public let firstName: String?
    public let lastName: String?
    public let email: String?
    public let inviteType: InviteType?

    public init(
        id: String,
        groupId: String,
        firstName: String? = nil,
        lastName: String? = nil,
        email: String? = nil,
        inviteType: InviteType? = nil
    ) {
        self.id = id
        self.groupId = groupId
        self.firstName = firstName
        self.lastName = lastName
        self.email = email
        self.inviteType = inviteType
    }

    public var displayName: String {
        let parts = [firstName, lastName].compactMap { $0 }.filter { !$0.isEmpty }
        return parts.isEmpty ? (email ?? id) : parts.joined(separator: " ")
    }

    public enum InviteType: String, Sendable, Codable {
        case email = "EMAIL"
        case publicLink = "PUBLIC_LINK"
    }
}

extension BetaTester: Codable {
    private enum CodingKeys: String, CodingKey {
        case id, groupId, firstName, lastName, email, inviteType
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        groupId = try container.decode(String.self, forKey: .groupId)
        firstName = try container.decodeIfPresent(String.self, forKey: .firstName)
        lastName = try container.decodeIfPresent(String.self, forKey: .lastName)
        email = try container.decodeIfPresent(String.self, forKey: .email)
        inviteType = try container.decodeIfPresent(InviteType.self, forKey: .inviteType)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(groupId, forKey: .groupId)
        try container.encodeIfPresent(firstName, forKey: .firstName)
        try container.encodeIfPresent(lastName, forKey: .lastName)
        try container.encodeIfPresent(email, forKey: .email)
        try container.encodeIfPresent(inviteType, forKey: .inviteType)
    }
}

extension BetaTester: Presentable {
    public static var tableHeaders: [String] { ["ID", "Name", "Email", "Invite Type"] }
    public var tableRow: [String] { [id, displayName, email ?? "-", inviteType?.rawValue ?? "-"] }
}

extension BetaTester: AffordanceProviding {
    public var affordances: [String: String] {
        [
            "listTesters": "asc testflight testers list --beta-group-id \(groupId)",
            "remove": "asc testflight testers remove --beta-group-id \(groupId) --tester-id \(id)",
        ]
    }
}
