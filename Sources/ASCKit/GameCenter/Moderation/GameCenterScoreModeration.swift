/// A score submitted to a Game Center leaderboard, as seen by the developer
/// moderating it (ASC API: `gameCenterScoreModerations`).
///
/// `rank` and `score` stay strings so 64-bit leaderboard values survive JSON
/// round trips without precision loss.
public struct GameCenterScoreModeration: Sendable, Equatable, Identifiable {
    public let id: String
    /// Parent leaderboard identifier — injected by Infrastructure on list.
    /// `nil` after a block/unblock, since that response doesn't name the leaderboard.
    public let leaderboardId: String?
    public let rank: String?
    public let score: String?
    /// ISO-8601 timestamp of the submission.
    public let submittedDate: String?
    /// The score is hidden from the leaderboard.
    public let isBlocked: Bool
    /// The score came from a pre-release (TestFlight / development) build.
    public let isPreReleased: Bool
    public let context: String?
    public let challengeIds: [String]
    public let playerId: String?
    public let playerNickname: String?
    /// Whether the submitting player is blocked from all leaderboards; `nil` when unknown.
    public let isPlayerBlocked: Bool?

    public init(
        id: String,
        leaderboardId: String?,
        rank: String?,
        score: String?,
        submittedDate: String?,
        isBlocked: Bool,
        isPreReleased: Bool,
        context: String?,
        challengeIds: [String],
        playerId: String?,
        playerNickname: String?,
        isPlayerBlocked: Bool?
    ) {
        self.id = id
        self.leaderboardId = leaderboardId
        self.rank = rank
        self.score = score
        self.submittedDate = submittedDate
        self.isBlocked = isBlocked
        self.isPreReleased = isPreReleased
        self.context = context
        self.challengeIds = challengeIds
        self.playerId = playerId
        self.playerNickname = playerNickname
        self.isPlayerBlocked = isPlayerBlocked
    }
}

extension GameCenterScoreModeration: Codable {
    enum CodingKeys: String, CodingKey {
        case id, leaderboardId, rank, score, submittedDate, isBlocked, isPreReleased
        case context, challengeIds, playerId, playerNickname, isPlayerBlocked
    }

    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        leaderboardId = try c.decodeIfPresent(String.self, forKey: .leaderboardId)
        rank = try c.decodeIfPresent(String.self, forKey: .rank)
        score = try c.decodeIfPresent(String.self, forKey: .score)
        submittedDate = try c.decodeIfPresent(String.self, forKey: .submittedDate)
        isBlocked = try c.decode(Bool.self, forKey: .isBlocked)
        isPreReleased = try c.decode(Bool.self, forKey: .isPreReleased)
        context = try c.decodeIfPresent(String.self, forKey: .context)
        challengeIds = try c.decodeIfPresent([String].self, forKey: .challengeIds) ?? []
        playerId = try c.decodeIfPresent(String.self, forKey: .playerId)
        playerNickname = try c.decodeIfPresent(String.self, forKey: .playerNickname)
        isPlayerBlocked = try c.decodeIfPresent(Bool.self, forKey: .isPlayerBlocked)
    }

    public func encode(to encoder: any Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encodeIfPresent(leaderboardId, forKey: .leaderboardId)
        try c.encodeIfPresent(rank, forKey: .rank)
        try c.encodeIfPresent(score, forKey: .score)
        try c.encodeIfPresent(submittedDate, forKey: .submittedDate)
        try c.encode(isBlocked, forKey: .isBlocked)
        try c.encode(isPreReleased, forKey: .isPreReleased)
        try c.encodeIfPresent(context, forKey: .context)
        try c.encode(challengeIds, forKey: .challengeIds)
        try c.encodeIfPresent(playerId, forKey: .playerId)
        try c.encodeIfPresent(playerNickname, forKey: .playerNickname)
        try c.encodeIfPresent(isPlayerBlocked, forKey: .isPlayerBlocked)
    }
}

extension GameCenterScoreModeration: Presentable {
    public static var tableHeaders: [String] {
        ["ID", "Rank", "Score", "Player", "Submitted", "Blocked"]
    }
    public var tableRow: [String] {
        [id, rank ?? "-", score ?? "-", playerNickname ?? playerId ?? "-", submittedDate ?? "-", isBlocked ? "yes" : "no"]
    }
}

extension GameCenterScoreModeration: AffordanceProviding {
    public var structuredAffordances: [Affordance] {
        var items: [Affordance] = []
        if let leaderboardId {
            items.append(Affordance(key: "listScoreModerations", command: "game-center score-moderations", action: "list",
                                    params: ["leaderboard-id": leaderboardId]))
        }
        if isBlocked {
            items.append(Affordance(key: "unblock", command: "game-center score-moderations", action: "unblock",
                                    params: ["moderation-id": id]))
        } else {
            items.append(Affordance(key: "block", command: "game-center score-moderations", action: "block",
                                    params: ["moderation-id": id]))
        }
        if let playerId, isPlayerBlocked == false {
            items.append(Affordance(key: "blockPlayer", command: "game-center players", action: "block",
                                    params: ["player-id": playerId]))
        }
        return items
    }
}
