public struct GameCenterDetail: Sendable, Equatable, Identifiable, Codable {
    public let id: String
    /// Parent app identifier — injected by Infrastructure since ASC API omits it from the response body
    public let appId: String
    public let isArcadeEnabled: Bool

    public init(id: String, appId: String, isArcadeEnabled: Bool) {
        self.id = id
        self.appId = appId
        self.isArcadeEnabled = isArcadeEnabled
    }
}

extension GameCenterDetail: AffordanceProviding {
    public var affordances: [String: String] {
        [
            "getDetail": "asc game-center detail get --app-id \(appId)",
            "listAchievements": "asc game-center achievements list --detail-id \(id)",
            "listLeaderboards": "asc game-center leaderboards list --detail-id \(id)",
        ]
    }
}
