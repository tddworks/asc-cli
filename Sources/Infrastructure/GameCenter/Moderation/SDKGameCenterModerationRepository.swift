@preconcurrency import AppStoreConnect_Swift_SDK
import Domain
import Foundation

public struct SDKGameCenterModerationRepository: GameCenterModerationRepository, @unchecked Sendable {
    private let client: any APIClient

    public init(client: any APIClient) {
        self.client = client
    }

    // MARK: - Score moderations

    public func listScoreModerations(leaderboardId: String, blockedOnly: Bool) async throws -> [Domain.GameCenterScoreModeration] {
        let pages = try await client.requestAllPages(
            APIEndpoint.v2.gameCenterLeaderboards.id(leaderboardId).gameCenterScoreModerations.get(
                parameters: .init(isExistsBlocked: blockedOnly ? true : nil, limit: 200, include: [.player])
            ),
            nextCursor: { $0.meta?.paging.nextCursor }
        )
        let players = Dictionary(
            pages.flatMap { $0.included ?? [] }.map { ($0.id, $0) },
            uniquingKeysWith: { first, _ in first }
        )
        return pages.flatMap(\.data).map { mapScore($0, leaderboardId: leaderboardId, players: players) }
    }

    public func updateScoreModeration(id: String, isBlocked: Bool) async throws -> Domain.GameCenterScoreModeration {
        let body = GameCenterScoreModerationUpdateRequest(data: .init(
            type: .gameCenterScoreModerations, id: id, attributes: .init(isBlocked: isBlocked)
        ))
        let response = try await client.request(APIEndpoint.v1.gameCenterScoreModerations.id(id).patch(body))
        let players = Dictionary(
            (response.included ?? []).map { ($0.id, $0) },
            uniquingKeysWith: { first, _ in first }
        )
        return mapScore(response.data, leaderboardId: nil, players: players, defaultBlocked: isBlocked)
    }

    // MARK: - Players

    public func listBlockedPlayers(gameCenterDetailId: String) async throws -> [Domain.GameCenterPlayer] {
        let pages = try await client.requestAllPages(
            APIEndpoint.v1.gameCenterDetails.id(gameCenterDetailId).blockedPlayers.get(limit: 200),
            nextCursor: { $0.meta?.paging.nextCursor }
        )
        // Everyone on this list is blocked by definition.
        return pages.flatMap(\.data).map { mapPlayer($0, gameCenterDetailId: gameCenterDetailId, defaultBlocked: true) }
    }

    public func updatePlayer(id: String, isBlocked: Bool) async throws -> Domain.GameCenterPlayer {
        let body = GameCenterDetailPlayerUpdateRequest(data: .init(
            type: .gameCenterDetailPlayers, id: id, attributes: .init(isBlocked: isBlocked)
        ))
        let response = try await client.request(APIEndpoint.v1.gameCenterDetailPlayers.id(id).patch(body))
        return mapPlayer(response.data, gameCenterDetailId: nil, defaultBlocked: isBlocked)
    }

    // MARK: - Mappers

    private func mapScore(
        _ sdk: AppStoreConnect_Swift_SDK.GameCenterScoreModeration,
        leaderboardId: String?,
        players: [String: AppStoreConnect_Swift_SDK.GameCenterDetailPlayer],
        defaultBlocked: Bool = false
    ) -> Domain.GameCenterScoreModeration {
        let playerId = sdk.relationships?.player?.data?.id
        let player = playerId.flatMap { players[$0] }
        return Domain.GameCenterScoreModeration(
            id: sdk.id,
            leaderboardId: leaderboardId,
            rank: sdk.attributes?.rank,
            score: sdk.attributes?.score,
            submittedDate: sdk.attributes?.submittedDate.map { ISO8601DateFormatter().string(from: $0) },
            isBlocked: sdk.attributes?.isBlocked ?? defaultBlocked,
            isPreReleased: sdk.attributes?.isPreReleased ?? false,
            context: sdk.attributes?.context,
            challengeIds: sdk.attributes?.challengeIDs ?? [],
            playerId: playerId,
            playerNickname: player?.attributes?.nickname,
            isPlayerBlocked: player?.attributes?.isBlocked
        )
    }

    private func mapPlayer(
        _ sdk: AppStoreConnect_Swift_SDK.GameCenterDetailPlayer,
        gameCenterDetailId: String?,
        defaultBlocked: Bool
    ) -> Domain.GameCenterPlayer {
        Domain.GameCenterPlayer(
            id: sdk.id,
            gameCenterDetailId: gameCenterDetailId,
            nickname: sdk.attributes?.nickname,
            bundleId: sdk.attributes?.bundleID,
            isBlocked: sdk.attributes?.isBlocked ?? defaultBlocked
        )
    }
}
