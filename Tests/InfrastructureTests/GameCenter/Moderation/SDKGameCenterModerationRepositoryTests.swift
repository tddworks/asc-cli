@preconcurrency import AppStoreConnect_Swift_SDK
import Foundation
import Testing
@testable import Infrastructure
@testable import Domain

@Suite
struct SDKGameCenterModerationRepositoryTests {

    // MARK: - Score moderations

    @Test func `should tie each score to the leaderboard it was listed under along with its player`() async throws {
        let stub = StubAPIClient()
        stub.willReturn(GameCenterScoreModerationsResponse(
            data: [
                AppStoreConnect_Swift_SDK.GameCenterScoreModeration(
                    type: .gameCenterScoreModerations,
                    id: "mod-1",
                    attributes: .init(
                        rank: "1",
                        score: "9223372036854775807",
                        submittedDate: Date(timeIntervalSince1970: 1_767_225_600),
                        isBlocked: false,
                        isPreReleased: true,
                        context: "ctx",
                        challengeIDs: ["ch-1"]
                    ),
                    relationships: .init(player: .init(data: .init(type: .gameCenterDetailPlayers, id: "player-1")))
                ),
            ],
            included: [
                AppStoreConnect_Swift_SDK.GameCenterDetailPlayer(
                    type: .gameCenterDetailPlayers,
                    id: "player-1",
                    attributes: .init(nickname: "Player One", isBlocked: false, bundleID: "com.example.game")
                ),
            ],
            links: .init(this: "")
        ))

        let repo = SDKGameCenterModerationRepository(client: stub)
        let result = try await repo.listScoreModerations(leaderboardId: "lb-42", blockedOnly: false)

        #expect(result == [
            Domain.GameCenterScoreModeration(
                id: "mod-1",
                leaderboardId: "lb-42",
                rank: "1",
                score: "9223372036854775807",
                submittedDate: "2026-01-01T00:00:00Z",
                isBlocked: false,
                isPreReleased: true,
                context: "ctx",
                challengeIds: ["ch-1"],
                playerId: "player-1",
                playerNickname: "Player One",
                isPlayerBlocked: false
            ),
        ])
    }

    @Test func `should leave the player's nickname and blocked state unknown when App Store Connect doesn't include the player`() async throws {
        let stub = StubAPIClient()
        stub.willReturn(GameCenterScoreModerationsResponse(
            data: [
                AppStoreConnect_Swift_SDK.GameCenterScoreModeration(
                    type: .gameCenterScoreModerations,
                    id: "mod-1",
                    attributes: .init(isBlocked: true),
                    relationships: .init(player: .init(data: .init(type: .gameCenterDetailPlayers, id: "player-1")))
                ),
            ],
            links: .init(this: "")
        ))

        let repo = SDKGameCenterModerationRepository(client: stub)
        let result = try await repo.listScoreModerations(leaderboardId: "lb-42", blockedOnly: true)

        #expect(result == [
            Domain.GameCenterScoreModeration(
                id: "mod-1", leaderboardId: "lb-42", rank: nil, score: nil, submittedDate: nil,
                isBlocked: true, isPreReleased: false, context: nil, challengeIds: [],
                playerId: "player-1", playerNickname: nil, isPlayerBlocked: nil
            ),
        ])
    }

    @Test func `should list every score when the leaderboard has more than one page`() async throws {
        func page(_ range: Range<Int>, nextCursor: String?) -> GameCenterScoreModerationsResponse {
            GameCenterScoreModerationsResponse(
                data: range.map { i in
                    AppStoreConnect_Swift_SDK.GameCenterScoreModeration(type: .gameCenterScoreModerations, id: "mod-\(i)")
                },
                links: .init(this: ""),
                meta: .init(paging: .init(total: 250, limit: 200, nextCursor: nextCursor))
            )
        }
        let stub = StubAPIClient()
        stub.willReturnPages([page(0..<200, nextCursor: "page-2"), page(200..<250, nextCursor: nil)])

        let repo = SDKGameCenterModerationRepository(client: stub)
        let result = try await repo.listScoreModerations(leaderboardId: "lb-42", blockedOnly: false)

        #expect(result.count == 250)
        #expect(result.last?.id == "mod-249")
    }

    @Test func `should show the score as blocked after blocking it`() async throws {
        let stub = StubAPIClient()
        stub.willReturn(GameCenterScoreModerationResponse(
            data: AppStoreConnect_Swift_SDK.GameCenterScoreModeration(
                type: .gameCenterScoreModerations,
                id: "mod-1",
                attributes: .init(rank: "3", score: "1200", isBlocked: true, isPreReleased: false),
                relationships: .init(player: .init(data: .init(type: .gameCenterDetailPlayers, id: "player-1")))
            ),
            links: .init(this: "")
        ))

        let repo = SDKGameCenterModerationRepository(client: stub)
        let result = try await repo.updateScoreModeration(id: "mod-1", isBlocked: true)

        #expect(result == Domain.GameCenterScoreModeration(
            id: "mod-1", leaderboardId: nil, rank: "3", score: "1200", submittedDate: nil,
            isBlocked: true, isPreReleased: false, context: nil, challengeIds: [],
            playerId: "player-1", playerNickname: nil, isPlayerBlocked: nil
        ))
    }

    @Test func `should show the score as unblocked when App Store Connect omits the flag after unblocking`() async throws {
        let stub = StubAPIClient()
        stub.willReturn(GameCenterScoreModerationResponse(
            data: AppStoreConnect_Swift_SDK.GameCenterScoreModeration(type: .gameCenterScoreModerations, id: "mod-1"),
            links: .init(this: "")
        ))

        let repo = SDKGameCenterModerationRepository(client: stub)
        let result = try await repo.updateScoreModeration(id: "mod-1", isBlocked: false)

        #expect(result.isBlocked == false)
    }

    // MARK: - Players

    @Test func `should tie each blocked player to the Game Center detail it was listed under`() async throws {
        let stub = StubAPIClient()
        stub.willReturn(GameCenterDetailPlayersResponse(
            data: [
                AppStoreConnect_Swift_SDK.GameCenterDetailPlayer(
                    type: .gameCenterDetailPlayers,
                    id: "player-1",
                    attributes: .init(nickname: "Player One", isBlocked: true, bundleID: "com.example.game")
                ),
            ],
            links: .init(this: "")
        ))

        let repo = SDKGameCenterModerationRepository(client: stub)
        let result = try await repo.listBlockedPlayers(gameCenterDetailId: "gc-42")

        #expect(result == [
            Domain.GameCenterPlayer(
                id: "player-1", gameCenterDetailId: "gc-42", nickname: "Player One",
                bundleId: "com.example.game", isBlocked: true
            ),
        ])
    }

    @Test func `should treat players on the blocked list as blocked when App Store Connect omits the flag`() async throws {
        let stub = StubAPIClient()
        stub.willReturn(GameCenterDetailPlayersResponse(
            data: [AppStoreConnect_Swift_SDK.GameCenterDetailPlayer(type: .gameCenterDetailPlayers, id: "player-1")],
            links: .init(this: "")
        ))

        let repo = SDKGameCenterModerationRepository(client: stub)
        let result = try await repo.listBlockedPlayers(gameCenterDetailId: "gc-42")

        #expect(result.map(\.isBlocked) == [true])
    }

    @Test func `should list every blocked player when there is more than one page`() async throws {
        func page(_ range: Range<Int>, nextCursor: String?) -> GameCenterDetailPlayersResponse {
            GameCenterDetailPlayersResponse(
                data: range.map { i in
                    AppStoreConnect_Swift_SDK.GameCenterDetailPlayer(type: .gameCenterDetailPlayers, id: "player-\(i)")
                },
                links: .init(this: ""),
                meta: .init(paging: .init(total: 230, limit: 200, nextCursor: nextCursor))
            )
        }
        let stub = StubAPIClient()
        stub.willReturnPages([page(0..<200, nextCursor: "page-2"), page(200..<230, nextCursor: nil)])

        let repo = SDKGameCenterModerationRepository(client: stub)
        let result = try await repo.listBlockedPlayers(gameCenterDetailId: "gc-42")

        #expect(result.count == 230)
        #expect(result.last?.id == "player-229")
    }

    @Test func `should show the player as unblocked after unblocking them`() async throws {
        let stub = StubAPIClient()
        stub.willReturn(GameCenterDetailPlayerResponse(
            data: AppStoreConnect_Swift_SDK.GameCenterDetailPlayer(
                type: .gameCenterDetailPlayers,
                id: "player-1",
                attributes: .init(nickname: "Player One", isBlocked: false, bundleID: "com.example.game")
            ),
            links: .init(this: "")
        ))

        let repo = SDKGameCenterModerationRepository(client: stub)
        let result = try await repo.updatePlayer(id: "player-1", isBlocked: false)

        #expect(result == Domain.GameCenterPlayer(
            id: "player-1", gameCenterDetailId: nil, nickname: "Player One",
            bundleId: "com.example.game", isBlocked: false
        ))
    }

    @Test func `should show the player as blocked when App Store Connect omits the flag after blocking`() async throws {
        let stub = StubAPIClient()
        stub.willReturn(GameCenterDetailPlayerResponse(
            data: AppStoreConnect_Swift_SDK.GameCenterDetailPlayer(type: .gameCenterDetailPlayers, id: "player-1"),
            links: .init(this: "")
        ))

        let repo = SDKGameCenterModerationRepository(client: stub)
        let result = try await repo.updatePlayer(id: "player-1", isBlocked: true)

        #expect(result.isBlocked == true)
    }
}
