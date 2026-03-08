public enum ScoreSortType: String, Sendable, Codable, Equatable {
    case asc = "ASC"
    case desc = "DESC"
}

public enum LeaderboardSubmissionType: String, Sendable, Codable, Equatable {
    case bestScore = "BEST_SCORE"
    case mostRecentScore = "MOST_RECENT_SCORE"
}

public struct GameCenterLeaderboard: Sendable, Equatable, Identifiable, Codable {
    public let id: String
    /// Parent Game Center detail identifier — injected by Infrastructure
    public let gameCenterDetailId: String
    public let referenceName: String
    public let vendorIdentifier: String
    public let scoreSortType: ScoreSortType
    public let submissionType: LeaderboardSubmissionType
    public let isArchived: Bool

    public init(
        id: String,
        gameCenterDetailId: String,
        referenceName: String,
        vendorIdentifier: String,
        scoreSortType: ScoreSortType,
        submissionType: LeaderboardSubmissionType,
        isArchived: Bool
    ) {
        self.id = id
        self.gameCenterDetailId = gameCenterDetailId
        self.referenceName = referenceName
        self.vendorIdentifier = vendorIdentifier
        self.scoreSortType = scoreSortType
        self.submissionType = submissionType
        self.isArchived = isArchived
    }
}

extension GameCenterLeaderboard: AffordanceProviding {
    public var affordances: [String: String] {
        [
            "listLeaderboards": "asc game-center leaderboards list --detail-id \(gameCenterDetailId)",
            "delete": "asc game-center leaderboards delete --leaderboard-id \(id)",
        ]
    }
}
