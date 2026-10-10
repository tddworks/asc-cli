import Foundation
import Testing
@testable import Domain

// MARK: - GameCenterScoreModeration

@Suite
struct GameCenterScoreModerationTests {

    @Test func `should belong to the leaderboard it was listed under`() {
        let moderation = MockRepositoryFactory.makeGameCenterScoreModeration(id: "mod-1", leaderboardId: "lb-9")
        #expect(moderation.leaderboardId == "lb-9")
    }

    @Test func `should offer block when the score is visible`() {
        let moderation = MockRepositoryFactory.makeGameCenterScoreModeration(id: "mod-1", isBlocked: false)
        #expect(moderation.affordances["block"] == "asc game-center score-moderations block --moderation-id mod-1")
        #expect(moderation.affordances["unblock"] == nil)
    }

    @Test func `should offer unblock when the score is blocked`() {
        let moderation = MockRepositoryFactory.makeGameCenterScoreModeration(id: "mod-1", isBlocked: true)
        #expect(moderation.affordances["unblock"] == "asc game-center score-moderations unblock --moderation-id mod-1")
        #expect(moderation.affordances["block"] == nil)
    }

    @Test func `should offer blocking the player when the player is not blocked yet`() {
        let moderation = MockRepositoryFactory.makeGameCenterScoreModeration(playerId: "player-7", isPlayerBlocked: false)
        #expect(moderation.affordances["blockPlayer"] == "asc game-center players block --player-id player-7")
    }

    @Test func `should not offer blocking the player when the player is already blocked`() {
        let moderation = MockRepositoryFactory.makeGameCenterScoreModeration(playerId: "player-7", isPlayerBlocked: true)
        #expect(moderation.affordances["blockPlayer"] == nil)
    }

    @Test func `should not offer blocking the player when the player is unknown`() {
        let moderation = MockRepositoryFactory.makeGameCenterScoreModeration(playerId: nil, isPlayerBlocked: nil)
        #expect(moderation.affordances["blockPlayer"] == nil)
    }

    @Test func `should point back to the leaderboard's scores when the leaderboard is known`() {
        let moderation = MockRepositoryFactory.makeGameCenterScoreModeration(leaderboardId: "lb-9")
        #expect(moderation.affordances["listScoreModerations"] == "asc game-center score-moderations list --leaderboard-id lb-9")
    }

    @Test func `should not point back to the leaderboard's scores when the leaderboard is unknown`() {
        let moderation = MockRepositoryFactory.makeGameCenterScoreModeration(leaderboardId: nil)
        #expect(moderation.affordances["listScoreModerations"] == nil)
    }

    @Test func `should link block, block player and the score list over REST`() {
        let moderation = MockRepositoryFactory.makeGameCenterScoreModeration(
            id: "mod-1", leaderboardId: "lb-9", isBlocked: false, playerId: "player-7", isPlayerBlocked: false
        )
        #expect(moderation.apiLinks["block"] == APILink(href: "/api/v1/game-center/score-moderations/mod-1/block", method: "POST"))
        #expect(moderation.apiLinks["blockPlayer"] == APILink(href: "/api/v1/game-center/players/player-7/block", method: "POST"))
        #expect(moderation.apiLinks["listScoreModerations"] == APILink(href: "/api/v1/game-center/leaderboards/lb-9/score-moderations", method: "GET"))
    }

    @Test func `should link unblock over REST when the score is blocked`() {
        let moderation = MockRepositoryFactory.makeGameCenterScoreModeration(id: "mod-1", isBlocked: true)
        #expect(moderation.apiLinks["unblock"] == APILink(href: "/api/v1/game-center/score-moderations/mod-1/unblock", method: "POST"))
    }

    @Test func `should leave unknown fields out of the JSON`() throws {
        let moderation = MockRepositoryFactory.makeGameCenterScoreModeration(
            id: "mod-1", leaderboardId: nil, rank: nil, score: nil, submittedDate: nil,
            context: nil, challengeIds: [], playerId: nil, playerNickname: nil, isPlayerBlocked: nil
        )
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        let json = String(decoding: try encoder.encode(moderation), as: UTF8.self)
        #expect(json == #"{"challengeIds":[],"id":"mod-1","isBlocked":false,"isPreReleased":false}"#)
    }

    @Test func `should show rank, score, player and blocked state in a table`() {
        let moderation = MockRepositoryFactory.makeGameCenterScoreModeration(
            id: "mod-1", rank: "3", score: "1200", submittedDate: "2026-01-01T00:00:00Z",
            isBlocked: true, playerNickname: "Player One"
        )
        #expect(GameCenterScoreModeration.tableHeaders == ["ID", "Rank", "Score", "Player", "Submitted", "Blocked"])
        #expect(moderation.tableRow == ["mod-1", "3", "1200", "Player One", "2026-01-01T00:00:00Z", "yes"])
    }
}

// MARK: - GameCenterPlayer

@Suite
struct GameCenterPlayerTests {

    @Test func `should belong to the Game Center detail it was listed under`() {
        let player = MockRepositoryFactory.makeGameCenterPlayer(id: "player-1", gameCenterDetailId: "gc-9")
        #expect(player.gameCenterDetailId == "gc-9")
    }

    @Test func `should offer unblock when the player is blocked`() {
        let player = MockRepositoryFactory.makeGameCenterPlayer(id: "player-1", isBlocked: true)
        #expect(player.affordances["unblock"] == "asc game-center players unblock --player-id player-1")
        #expect(player.affordances["block"] == nil)
    }

    @Test func `should offer block when the player is not blocked`() {
        let player = MockRepositoryFactory.makeGameCenterPlayer(id: "player-1", isBlocked: false)
        #expect(player.affordances["block"] == "asc game-center players block --player-id player-1")
        #expect(player.affordances["unblock"] == nil)
    }

    @Test func `should point to the blocked players list when the Game Center detail is known`() {
        let player = MockRepositoryFactory.makeGameCenterPlayer(gameCenterDetailId: "gc-9")
        #expect(player.affordances["listBlockedPlayers"] == "asc game-center blocked-players list --detail-id gc-9")
    }

    @Test func `should not point to the blocked players list when the Game Center detail is unknown`() {
        let player = MockRepositoryFactory.makeGameCenterPlayer(gameCenterDetailId: nil)
        #expect(player.affordances["listBlockedPlayers"] == nil)
    }

    @Test func `should link unblock and the blocked players list over REST`() {
        let player = MockRepositoryFactory.makeGameCenterPlayer(id: "player-1", gameCenterDetailId: "gc-9", isBlocked: true)
        #expect(player.apiLinks["unblock"] == APILink(href: "/api/v1/game-center/players/player-1/unblock", method: "POST"))
        #expect(player.apiLinks["listBlockedPlayers"] == APILink(href: "/api/v1/game-center/details/gc-9/blocked-players", method: "GET"))
    }

    @Test func `should leave unknown fields out of the JSON`() throws {
        let player = MockRepositoryFactory.makeGameCenterPlayer(
            id: "player-1", gameCenterDetailId: nil, nickname: nil, bundleId: nil, isBlocked: false
        )
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        let json = String(decoding: try encoder.encode(player), as: UTF8.self)
        #expect(json == #"{"id":"player-1","isBlocked":false}"#)
    }

    @Test func `should show nickname, bundle id and blocked state in a table`() {
        let player = MockRepositoryFactory.makeGameCenterPlayer(
            id: "player-1", nickname: "Player One", bundleId: "com.example.game", isBlocked: true
        )
        #expect(GameCenterPlayer.tableHeaders == ["ID", "Nickname", "Bundle ID", "Blocked"])
        #expect(player.tableRow == ["player-1", "Player One", "com.example.game", "yes"])
    }
}
