import Foundation

public struct BetaGroup: Sendable, Codable, Equatable, Identifiable {
    public let id: String
    public let appId: String
    public let name: String
    public let isInternalGroup: Bool
    public let publicLinkEnabled: Bool
    public let createdDate: Date?

    public init(
        id: String,
        appId: String,
        name: String,
        isInternalGroup: Bool = false,
        publicLinkEnabled: Bool = false,
        createdDate: Date? = nil
    ) {
        self.id = id
        self.appId = appId
        self.name = name
        self.isInternalGroup = isInternalGroup
        self.publicLinkEnabled = publicLinkEnabled
        self.createdDate = createdDate
    }
}

extension BetaGroup: Presentable {
    public static var tableHeaders: [String] { ["ID", "Name", "Internal", "Public Link"] }
    public var tableRow: [String] { [id, name, isInternalGroup ? "Yes" : "No", publicLinkEnabled ? "Yes" : "No"] }
}

extension BetaGroup: AffordanceProviding {
    public var affordances: [String: String] {
        [
            "exportTesters": "asc testflight testers export --beta-group-id \(id)",
            "importTesters": "asc testflight testers import --beta-group-id \(id) --file testers.csv",
            "listTesters": "asc testflight testers list --beta-group-id \(id)",
        ]
    }
}
