import Mockable

@Mockable
public protocol GameCenterRepository: Sendable {
    func getDetail(appId: String) async throws -> GameCenterDetail

    func listAchievements(gameCenterDetailId: String) async throws -> [GameCenterAchievement]
    func createAchievement(
        gameCenterDetailId: String,
        referenceName: String,
        vendorIdentifier: String,
        points: Int,
        isShowBeforeEarned: Bool,
        isRepeatable: Bool
    ) async throws -> GameCenterAchievement
    func deleteAchievement(id: String) async throws

    func listLeaderboards(gameCenterDetailId: String) async throws -> [GameCenterLeaderboard]
    func createLeaderboard(
        gameCenterDetailId: String,
        referenceName: String,
        vendorIdentifier: String,
        scoreSortType: ScoreSortType,
        submissionType: LeaderboardSubmissionType
    ) async throws -> GameCenterLeaderboard
    func deleteLeaderboard(id: String) async throws
}
