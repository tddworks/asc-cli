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

extension GameCenterDetail: Presentable {
    public static var tableHeaders: [String] {
        ["ID", "App ID", "Arcade Enabled"]
    }
    public var tableRow: [String] {
        [id, appId, isArcadeEnabled ? "yes" : "no"]
    }
}

extension GameCenterDetail: AffordanceProviding {
    public var structuredAffordances: [Affordance] {
        [
            Affordance(key: "getDetail", command: "game-center detail", action: "get", params: ["app-id": appId]),
            Affordance(key: "listAchievements", command: "game-center achievements", action: "list", params: ["detail-id": id]),
            Affordance(key: "listLeaderboards", command: "game-center leaderboards", action: "list", params: ["detail-id": id]),
            Affordance(key: "listBlockedPlayers", command: "game-center blocked-players", action: "list", params: ["detail-id": id]),
        ]
    }
}
