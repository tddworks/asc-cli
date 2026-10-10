import Mockable
import Testing
@testable import ASCCommand
@testable import Domain

private func makeScore(
    id: String = "mod-1",
    leaderboardId: String? = "lb-1",
    isBlocked: Bool = false,
    playerId: String? = "player-1",
    playerNickname: String? = "Player One",
    isPlayerBlocked: Bool? = false
) -> GameCenterScoreModeration {
    GameCenterScoreModeration(
        id: id,
        leaderboardId: leaderboardId,
        rank: "1",
        score: "9999",
        submittedDate: "2026-01-01T00:00:00Z",
        isBlocked: isBlocked,
        isPreReleased: false,
        context: nil,
        challengeIds: ["ch-1"],
        playerId: playerId,
        playerNickname: playerNickname,
        isPlayerBlocked: isPlayerBlocked
    )
}

@Suite
struct GameCenterScoreModerationsListTests {

    @Test func `should list the leaderboard's scores with their player and next moderation steps`() async throws {
        let mockRepo = MockGameCenterModerationRepository()
        given(mockRepo).listScoreModerations(leaderboardId: .any, blockedOnly: .any).willReturn([makeScore()])

        let cmd = try GameCenterScoreModerationsList.parse(["--leaderboard-id", "lb-1", "--pretty"])
        let output = try await cmd.execute(repo: mockRepo)

        #expect(output == """
        {
          "data" : [
            {
              "affordances" : {
                "block" : "asc game-center score-moderations block --moderation-id mod-1",
                "blockPlayer" : "asc game-center players block --player-id player-1",
                "listScoreModerations" : "asc game-center score-moderations list --leaderboard-id lb-1"
              },
              "challengeIds" : [
                "ch-1"
              ],
              "id" : "mod-1",
              "isBlocked" : false,
              "isPlayerBlocked" : false,
              "isPreReleased" : false,
              "leaderboardId" : "lb-1",
              "playerId" : "player-1",
              "playerNickname" : "Player One",
              "rank" : "1",
              "score" : "9999",
              "submittedDate" : "2026-01-01T00:00:00Z"
            }
          ]
        }
        """)
    }

    @Test func `should show only blocked scores when asked for blocked only`() async throws {
        let mockRepo = MockGameCenterModerationRepository()
        given(mockRepo).listScoreModerations(leaderboardId: .value("lb-1"), blockedOnly: .value(true))
            .willReturn([makeScore(id: "mod-2", isBlocked: true)])
        given(mockRepo).listScoreModerations(leaderboardId: .value("lb-1"), blockedOnly: .value(false))
            .willReturn([makeScore(id: "mod-1"), makeScore(id: "mod-2", isBlocked: true)])

        let cmd = try GameCenterScoreModerationsList.parse(["--leaderboard-id", "lb-1", "--blocked-only", "--output", "table"])
        let output = try await cmd.execute(repo: mockRepo)

        #expect(output == [
            "ID     Rank  Score  Player      Submitted             Blocked",
            "-----  ----  -----  ----------  --------------------  -------",
            "mod-2  1     9999   Player One  2026-01-01T00:00:00Z  yes    ",
        ].joined(separator: "\n"))
    }
}

@Suite
struct GameCenterScoreModerationsBlockTests {

    @Test func `should show the score as blocked and offer unblock`() async throws {
        let mockRepo = MockGameCenterModerationRepository()
        given(mockRepo).updateScoreModeration(id: .value("mod-1"), isBlocked: .value(true))
            .willReturn(makeScore(leaderboardId: nil, isBlocked: true, playerNickname: nil, isPlayerBlocked: nil))

        let cmd = try GameCenterScoreModerationsBlock.parse(["--moderation-id", "mod-1", "--pretty"])
        let output = try await cmd.execute(repo: mockRepo)

        #expect(output == """
        {
          "data" : [
            {
              "affordances" : {
                "unblock" : "asc game-center score-moderations unblock --moderation-id mod-1"
              },
              "challengeIds" : [
                "ch-1"
              ],
              "id" : "mod-1",
              "isBlocked" : true,
              "isPreReleased" : false,
              "playerId" : "player-1",
              "rank" : "1",
              "score" : "9999",
              "submittedDate" : "2026-01-01T00:00:00Z"
            }
          ]
        }
        """)
    }
}

@Suite
struct GameCenterScoreModerationsUnblockTests {

    @Test func `should show the score as visible again and offer block`() async throws {
        let mockRepo = MockGameCenterModerationRepository()
        given(mockRepo).updateScoreModeration(id: .value("mod-1"), isBlocked: .value(false))
            .willReturn(makeScore(leaderboardId: nil, isBlocked: false, playerNickname: nil, isPlayerBlocked: nil))

        let cmd = try GameCenterScoreModerationsUnblock.parse(["--moderation-id", "mod-1", "--pretty"])
        let output = try await cmd.execute(repo: mockRepo)

        #expect(output == """
        {
          "data" : [
            {
              "affordances" : {
                "block" : "asc game-center score-moderations block --moderation-id mod-1"
              },
              "challengeIds" : [
                "ch-1"
              ],
              "id" : "mod-1",
              "isBlocked" : false,
              "isPreReleased" : false,
              "playerId" : "player-1",
              "rank" : "1",
              "score" : "9999",
              "submittedDate" : "2026-01-01T00:00:00Z"
            }
          ]
        }
        """)
    }
}

@Suite
struct GameCenterBlockedPlayersListTests {

    @Test func `should list the game's blocked players and offer to unblock each`() async throws {
        let mockRepo = MockGameCenterModerationRepository()
        given(mockRepo).listBlockedPlayers(gameCenterDetailId: .any).willReturn([
            GameCenterPlayer(id: "player-1", gameCenterDetailId: "gc-1", nickname: "Player One",
                             bundleId: "com.example.game", isBlocked: true),
        ])

        let cmd = try GameCenterBlockedPlayersList.parse(["--detail-id", "gc-1", "--pretty"])
        let output = try await cmd.execute(repo: mockRepo)

        #expect(output == """
        {
          "data" : [
            {
              "affordances" : {
                "listBlockedPlayers" : "asc game-center blocked-players list --detail-id gc-1",
                "unblock" : "asc game-center players unblock --player-id player-1"
              },
              "bundleId" : "com.example.game",
              "gameCenterDetailId" : "gc-1",
              "id" : "player-1",
              "isBlocked" : true,
              "nickname" : "Player One"
            }
          ]
        }
        """)
    }
}

@Suite
struct GameCenterPlayersBlockTests {

    @Test func `should show the player as blocked and offer unblock`() async throws {
        let mockRepo = MockGameCenterModerationRepository()
        given(mockRepo).updatePlayer(id: .value("player-1"), isBlocked: .value(true)).willReturn(
            GameCenterPlayer(id: "player-1", gameCenterDetailId: nil, nickname: "Player One",
                             bundleId: nil, isBlocked: true)
        )

        let cmd = try GameCenterPlayersBlock.parse(["--player-id", "player-1", "--pretty"])
        let output = try await cmd.execute(repo: mockRepo)

        #expect(output == """
        {
          "data" : [
            {
              "affordances" : {
                "unblock" : "asc game-center players unblock --player-id player-1"
              },
              "id" : "player-1",
              "isBlocked" : true,
              "nickname" : "Player One"
            }
          ]
        }
        """)
    }
}

@Suite
struct GameCenterPlayersUnblockTests {

    @Test func `should show the player as unblocked and offer block`() async throws {
        let mockRepo = MockGameCenterModerationRepository()
        given(mockRepo).updatePlayer(id: .value("player-1"), isBlocked: .value(false)).willReturn(
            GameCenterPlayer(id: "player-1", gameCenterDetailId: nil, nickname: "Player One",
                             bundleId: nil, isBlocked: false)
        )

        let cmd = try GameCenterPlayersUnblock.parse(["--player-id", "player-1", "--pretty"])
        let output = try await cmd.execute(repo: mockRepo)

        #expect(output == """
        {
          "data" : [
            {
              "affordances" : {
                "block" : "asc game-center players block --player-id player-1"
              },
              "id" : "player-1",
              "isBlocked" : false,
              "nickname" : "Player One"
            }
          ]
        }
        """)
    }
}
