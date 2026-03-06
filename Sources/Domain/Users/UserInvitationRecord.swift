import Foundation

public struct UserInvitationRecord: Sendable, Equatable, Identifiable, Codable {
    public let id: String
    public let email: String
    public let firstName: String
    public let lastName: String
    public let roles: [UserRole]
    public let expirationDate: Date?
    public let isAllAppsVisible: Bool
    public let isProvisioningAllowed: Bool

    public init(
        id: String,
        email: String,
        firstName: String,
        lastName: String,
        roles: [UserRole],
        expirationDate: Date? = nil,
        isAllAppsVisible: Bool,
        isProvisioningAllowed: Bool
    ) {
        self.id = id
        self.email = email
        self.firstName = firstName
        self.lastName = lastName
        self.roles = roles
        self.expirationDate = expirationDate
        self.isAllAppsVisible = isAllAppsVisible
        self.isProvisioningAllowed = isProvisioningAllowed
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        email = try container.decode(String.self, forKey: .email)
        firstName = try container.decode(String.self, forKey: .firstName)
        lastName = try container.decode(String.self, forKey: .lastName)
        roles = try container.decode([UserRole].self, forKey: .roles)
        expirationDate = try container.decodeIfPresent(Date.self, forKey: .expirationDate)
        isAllAppsVisible = try container.decode(Bool.self, forKey: .isAllAppsVisible)
        isProvisioningAllowed = try container.decode(Bool.self, forKey: .isProvisioningAllowed)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(email, forKey: .email)
        try container.encode(firstName, forKey: .firstName)
        try container.encode(lastName, forKey: .lastName)
        try container.encode(roles, forKey: .roles)
        try container.encodeIfPresent(expirationDate, forKey: .expirationDate)
        try container.encode(isAllAppsVisible, forKey: .isAllAppsVisible)
        try container.encode(isProvisioningAllowed, forKey: .isProvisioningAllowed)
    }

    private enum CodingKeys: String, CodingKey {
        case id, email, firstName, lastName, roles, expirationDate
        case isAllAppsVisible, isProvisioningAllowed
    }
}

extension UserInvitationRecord: AffordanceProviding {
    public var affordances: [String: String] {
        [
            "cancel": "asc user-invitations cancel --invitation-id \(id)",
        ]
    }
}
