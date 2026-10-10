import Mockable

/// Moderates what players submit to Game Center: individual leaderboard scores
/// and the players themselves.
@Mockable
public protocol GameCenterModerationRepository: Sendable {
    func listScoreModerations(leaderboardId: String, blockedOnly: Bool) async throws -> [GameCenterScoreModeration]
    func updateScoreModeration(id: String, isBlocked: Bool) async throws -> GameCenterScoreModeration
    func listBlockedPlayers(gameCenterDetailId: String) async throws -> [GameCenterPlayer]
    func updatePlayer(id: String, isBlocked: Bool) async throws -> GameCenterPlayer
}
