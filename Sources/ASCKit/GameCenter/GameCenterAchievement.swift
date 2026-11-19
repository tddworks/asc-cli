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

extension GameCenterAchievement: Presentable {
    public static var tableHeaders: [String] {
        ["ID", "Reference Name", "Vendor ID", "Points"]
    }
    public var tableRow: [String] {
        [id, referenceName, vendorIdentifier, String(points)]
    }
}

extension GameCenterAchievement: AffordanceProviding {
    public var structuredAffordances: [Affordance] {
        [
            Affordance(key: "listAchievements", command: "game-center achievements", action: "list",
                       params: ["detail-id": gameCenterDetailId]),
            Affordance(key: "delete", command: "game-center achievements", action: "delete",
                       params: ["achievement-id": id]),
        ]
    }
}
