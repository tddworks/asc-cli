/// A Game Center player of the app (ASC API: `gameCenterDetailPlayers`).
///
/// A blocked player's scores are hidden from every leaderboard of the game.
public struct GameCenterPlayer: Sendable, Equatable, Identifiable {
    public let id: String
    /// Parent Game Center detail identifier — injected by Infrastructure on list.
    /// `nil` after a block/unblock, since that response doesn't name the detail.
    public let gameCenterDetailId: String?
    public let nickname: String?
    public let bundleId: String?
    public let isBlocked: Bool

    public init(id: String, gameCenterDetailId: String?, nickname: String?, bundleId: String?, isBlocked: Bool) {
        self.id = id
        self.gameCenterDetailId = gameCenterDetailId
        self.nickname = nickname
        self.bundleId = bundleId
        self.isBlocked = isBlocked
    }
}

extension GameCenterPlayer: Codable {
    enum CodingKeys: String, CodingKey {
        case id, gameCenterDetailId, nickname, bundleId, isBlocked
    }

    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        gameCenterDetailId = try c.decodeIfPresent(String.self, forKey: .gameCenterDetailId)
        nickname = try c.decodeIfPresent(String.self, forKey: .nickname)
        bundleId = try c.decodeIfPresent(String.self, forKey: .bundleId)
        isBlocked = try c.decode(Bool.self, forKey: .isBlocked)
    }

    public func encode(to encoder: any Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encodeIfPresent(gameCenterDetailId, forKey: .gameCenterDetailId)
        try c.encodeIfPresent(nickname, forKey: .nickname)
        try c.encodeIfPresent(bundleId, forKey: .bundleId)
        try c.encode(isBlocked, forKey: .isBlocked)
    }
}

extension GameCenterPlayer: Presentable {
    public static var tableHeaders: [String] {
        ["ID", "Nickname", "Bundle ID", "Blocked"]
    }
    public var tableRow: [String] {
        [id, nickname ?? "-", bundleId ?? "-", isBlocked ? "yes" : "no"]
    }
}

extension GameCenterPlayer: AffordanceProviding {
    public var structuredAffordances: [Affordance] {
        var items: [Affordance] = []
        if let gameCenterDetailId {
            items.append(Affordance(key: "listBlockedPlayers", command: "game-center blocked-players", action: "list",
                                    params: ["detail-id": gameCenterDetailId]))
        }
        let action = isBlocked ? "unblock" : "block"
        items.append(Affordance(key: action, command: "game-center players", action: action, params: ["player-id": id]))
        return items
    }
}
