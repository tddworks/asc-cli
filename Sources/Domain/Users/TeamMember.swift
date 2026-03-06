public struct TeamMember: Sendable, Equatable, Identifiable, Codable {
    public let id: String
    public let username: String
    public let firstName: String
    public let lastName: String
    public let roles: [UserRole]
    public let isAllAppsVisible: Bool
    public let isProvisioningAllowed: Bool

    public init(
        id: String,
        username: String,
        firstName: String,
        lastName: String,
        roles: [UserRole],
        isAllAppsVisible: Bool,
        isProvisioningAllowed: Bool
    ) {
        self.id = id
        self.username = username
        self.firstName = firstName
        self.lastName = lastName
        self.roles = roles
        self.isAllAppsVisible = isAllAppsVisible
        self.isProvisioningAllowed = isProvisioningAllowed
    }
}

extension TeamMember: AffordanceProviding {
    public var affordances: [String: String] {
        let roleFlags = roles.map { "--role \($0.rawValue)" }.joined(separator: " ")
        return [
            "remove": "asc users remove --user-id \(id)",
            "updateRoles": "asc users update --user-id \(id) \(roleFlags)",
        ]
    }
}
