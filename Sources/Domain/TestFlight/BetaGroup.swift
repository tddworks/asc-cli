import Foundation

public struct BetaGroup: Sendable, Codable, Equatable, Identifiable {
    public let id: String
    public let name: String
    public let isInternalGroup: Bool
    public let publicLinkEnabled: Bool
    public let createdDate: Date?

    public init(
        id: String,
        name: String,
        isInternalGroup: Bool = false,
        publicLinkEnabled: Bool = false,
        createdDate: Date? = nil
    ) {
        self.id = id
        self.name = name
        self.isInternalGroup = isInternalGroup
        self.publicLinkEnabled = publicLinkEnabled
        self.createdDate = createdDate
    }
}
