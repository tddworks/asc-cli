import Domain
import Foundation
import Hummingbird
import HummingbirdWebSocket
import Infrastructure

/// Routes for Game Center: the app's Game Center detail, its achievements and leaderboards,
/// and moderation of leaderboard scores and players.
///
/// Query-param names match the CLI flags: `?blocked-only=true`.
struct GameCenterController: Sendable {
    let repo: any GameCenterRepository
    let moderationRepo: any GameCenterModerationRepository

    /// A request body missing a required field; surfaced to the client as a 400.
    struct BadRequest: Error, Equatable {
        let message: String
        init(_ message: String) { self.message = message }
    }

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

        group.get("/game-center/details/:detailId/achievements") { _, context -> Response in
            guard let detailId = context.parameters.get("detailId") else { return jsonError("Missing detailId") }
            return try restFormat(try await self.repo.listAchievements(gameCenterDetailId: detailId))
        }

        group.post("/game-center/details/:detailId/achievements") { request, context -> Response in
            guard let detailId = context.parameters.get("detailId") else { return jsonError("Missing detailId") }
            let json = try await Self.jsonBody(request)
            do {
                return try restFormat(try await Self.createAchievement(detailId: detailId, json: json, repo: self.repo))
            } catch let error as BadRequest {
                return jsonError(error.message)
            }
        }

        group.post("/game-center/details/:detailId/leaderboards") { request, context -> Response in
            guard let detailId = context.parameters.get("detailId") else { return jsonError("Missing detailId") }
            let json = try await Self.jsonBody(request)
            do {
                return try restFormat(try await Self.createLeaderboard(detailId: detailId, json: json, repo: self.repo))
            } catch let error as BadRequest {
                return jsonError(error.message)
            }
        }

        group.delete("/game-center/achievements/:achievementId") { _, context -> Response in
            guard let achievementId = context.parameters.get("achievementId") else { return jsonError("Missing achievementId") }
            try await self.repo.deleteAchievement(id: achievementId)
            return restResponse("{\"deleted\":true}")
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

    /// Body keys mirror the `asc game-center achievements create` flags in camelCase:
    /// `{"referenceName", "vendorIdentifier", "points", "showBeforeEarned"?, "repeatable"?}`.
    static func createAchievement(
        detailId: String,
        json: [String: Any],
        repo: any GameCenterRepository
    ) async throws -> GameCenterAchievement {
        guard let referenceName = json["referenceName"] as? String,
              let vendorIdentifier = json["vendorIdentifier"] as? String,
              let points = json["points"] as? Int
        else { throw BadRequest("Provide referenceName, vendorIdentifier and points") }
        return try await repo.createAchievement(
            gameCenterDetailId: detailId,
            referenceName: referenceName,
            vendorIdentifier: vendorIdentifier,
            points: points,
            isShowBeforeEarned: json["showBeforeEarned"] as? Bool ?? false,
            isRepeatable: json["repeatable"] as? Bool ?? false
        )
    }

    /// Body keys mirror the `asc game-center leaderboards create` flags in camelCase:
    /// `{"referenceName", "vendorIdentifier", "scoreSortType", "submissionType"?}` (default `BEST_SCORE`).
    static func createLeaderboard(
        detailId: String,
        json: [String: Any],
        repo: any GameCenterRepository
    ) async throws -> GameCenterLeaderboard {
        guard let referenceName = json["referenceName"] as? String,
              let vendorIdentifier = json["vendorIdentifier"] as? String,
              let scoreSortType = (json["scoreSortType"] as? String).flatMap({ ScoreSortType(rawValue: $0.uppercased()) })
        else { throw BadRequest("Provide referenceName, vendorIdentifier and scoreSortType (ASC or DESC)") }
        guard let submissionType = LeaderboardSubmissionType(rawValue: (json["submissionType"] as? String ?? "BEST_SCORE").uppercased())
        else { throw BadRequest("submissionType must be BEST_SCORE or MOST_RECENT_SCORE") }
        return try await repo.createLeaderboard(
            gameCenterDetailId: detailId,
            referenceName: referenceName,
            vendorIdentifier: vendorIdentifier,
            scoreSortType: scoreSortType,
            submissionType: submissionType
        )
    }

    private static func jsonBody(_ request: Request) async throws -> [String: Any] {
        let body = try await request.body.collect(upTo: 64 * 1024)
        return (try? JSONSerialization.jsonObject(with: body) as? [String: Any]) ?? [:]
    }
}
