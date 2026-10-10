import Domain
import Foundation
import Hummingbird
import HummingbirdWebSocket
import Infrastructure

/// Routes for Game Center: the app's Game Center detail, its leaderboards,
/// and moderation of leaderboard scores and players.
///
/// Query-param names match the CLI flags: `?blocked-only=true`.
struct GameCenterController: Sendable {
    let repo: any GameCenterRepository
    let moderationRepo: any GameCenterModerationRepository

    func addRoutes(to group: RouterGroup<BasicWebSocketRequestContext>) {
        // MARK: Detail & leaderboards

        group.get("/apps/:appId/game-center") { _, context -> Response in
            guard let appId = context.parameters.get("appId") else { return jsonError("Missing appId") }
            return try restFormat(try await self.repo.getDetail(appId: appId))
        }

        group.get("/game-center/details/:detailId/leaderboards") { _, context -> Response in
            guard let detailId = context.parameters.get("detailId") else { return jsonError("Missing detailId") }
            return try restFormat(try await self.repo.listLeaderboards(gameCenterDetailId: detailId))
        }

        group.delete("/game-center/leaderboards/:leaderboardId") { _, context -> Response in
            guard let leaderboardId = context.parameters.get("leaderboardId") else { return jsonError("Missing leaderboardId") }
            try await self.repo.deleteLeaderboard(id: leaderboardId)
            return restResponse("{\"deleted\":true}")
        }

        // MARK: Score moderation

        group.get("/game-center/leaderboards/:leaderboardId/score-moderations") { request, context -> Response in
            guard let leaderboardId = context.parameters.get("leaderboardId") else { return jsonError("Missing leaderboardId") }
            let blockedOnly = request.uri.queryParameters.get("blocked-only") == "true"
            return try restFormat(
                try await self.moderationRepo.listScoreModerations(leaderboardId: leaderboardId, blockedOnly: blockedOnly)
            )
        }

        group.post("/game-center/score-moderations/:moderationId/block") { _, context -> Response in
            guard let moderationId = context.parameters.get("moderationId") else { return jsonError("Missing moderationId") }
            return try restFormat(try await self.moderationRepo.updateScoreModeration(id: moderationId, isBlocked: true))
        }

        group.post("/game-center/score-moderations/:moderationId/unblock") { _, context -> Response in
            guard let moderationId = context.parameters.get("moderationId") else { return jsonError("Missing moderationId") }
            return try restFormat(try await self.moderationRepo.updateScoreModeration(id: moderationId, isBlocked: false))
        }

        // MARK: Players

        group.get("/game-center/details/:detailId/blocked-players") { _, context -> Response in
            guard let detailId = context.parameters.get("detailId") else { return jsonError("Missing detailId") }
            return try restFormat(try await self.moderationRepo.listBlockedPlayers(gameCenterDetailId: detailId))
        }

        group.post("/game-center/players/:playerId/block") { _, context -> Response in
            guard let playerId = context.parameters.get("playerId") else { return jsonError("Missing playerId") }
            return try restFormat(try await self.moderationRepo.updatePlayer(id: playerId, isBlocked: true))
        }

        group.post("/game-center/players/:playerId/unblock") { _, context -> Response in
            guard let playerId = context.parameters.get("playerId") else { return jsonError("Missing playerId") }
            return try restFormat(try await self.moderationRepo.updatePlayer(id: playerId, isBlocked: false))
        }
    }
}
