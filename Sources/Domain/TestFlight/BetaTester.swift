public struct BetaTester: Sendable, Codable, Equatable, Identifiable {
    public let id: String
    public let firstName: String?
    public let lastName: String?
    public let email: String?
    public let inviteType: InviteType?

    public init(
        id: String,
        firstName: String? = nil,
        lastName: String? = nil,
        email: String? = nil,
        inviteType: InviteType? = nil
    ) {
        self.id = id
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
