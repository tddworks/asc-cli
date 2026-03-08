public struct GameCenterAchievement: Sendable, Equatable, Identifiable, Codable {
    public let id: String
    /// Parent Game Center detail identifier — injected by Infrastructure
    public let gameCenterDetailId: String
    public let referenceName: String
    public let vendorIdentifier: String
    public let points: Int
    public let isShowBeforeEarned: Bool
    public let isRepeatable: Bool
    public let isArchived: Bool

    public init(
        id: String,
        gameCenterDetailId: String,
        referenceName: String,
        vendorIdentifier: String,
        points: Int,
        isShowBeforeEarned: Bool,
        isRepeatable: Bool,
        isArchived: Bool
    ) {
        self.id = id
        self.gameCenterDetailId = gameCenterDetailId
        self.referenceName = referenceName
        self.vendorIdentifier = vendorIdentifier
        self.points = points
        self.isShowBeforeEarned = isShowBeforeEarned
        self.isRepeatable = isRepeatable
        self.isArchived = isArchived
    }
}

extension GameCenterAchievement: AffordanceProviding {
    public var affordances: [String: String] {
        [
            "listAchievements": "asc game-center achievements list --detail-id \(gameCenterDetailId)",
            "delete": "asc game-center achievements delete --achievement-id \(id)",
        ]
    }
}
