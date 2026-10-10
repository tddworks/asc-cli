import Foundation
import Testing
@testable import Domain

// MARK: - GameCenterDetail

@Suite
struct GameCenterDetailTests {

    @Test func `detail carries all fields`() {
        let detail = GameCenterDetail(id: "gc-1", appId: "app-42", isArcadeEnabled: true)
        #expect(detail.id == "gc-1")
        #expect(detail.appId == "app-42")
        #expect(detail.isArcadeEnabled == true)
    }

    @Test func `detail carries appId`() {
        let detail = MockRepositoryFactory.makeGameCenterDetail(id: "gc-1", appId: "app-1")
        #expect(detail.appId == "app-1")
    }

    @Test func `detail is arcade disabled by default`() {
        let detail = MockRepositoryFactory.makeGameCenterDetail()
        #expect(detail.isArcadeEnabled == false)
    }

    @Test func `detail affordances include get, list achievements, list leaderboards`() {
        let detail = MockRepositoryFactory.makeGameCenterDetail(id: "gc-1", appId: "app-1")
        #expect(detail.affordances["getDetail"] == "asc game-center detail get --app-id app-1")
        #expect(detail.affordances["listAchievements"] == "asc game-center achievements list --detail-id gc-1")
        #expect(detail.affordances["listLeaderboards"] == "asc game-center leaderboards list --detail-id gc-1")
    }

    @Test func `should point to the players blocked from its leaderboards`() {
        let detail = MockRepositoryFactory.makeGameCenterDetail(id: "gc-1", appId: "app-1")
        #expect(detail.affordances["listBlockedPlayers"] == "asc game-center blocked-players list --detail-id gc-1")
    }

    @Test func `should link its detail, achievements, leaderboards and blocked players over REST`() {
        let detail = MockRepositoryFactory.makeGameCenterDetail(id: "gc-1", appId: "app-1")
        #expect(detail.apiLinks["getDetail"] == APILink(href: "/api/v1/apps/app-1/game-center", method: "GET"))
        #expect(detail.apiLinks["listAchievements"] == APILink(href: "/api/v1/game-center/details/gc-1/achievements", method: "GET"))
        #expect(detail.apiLinks["listLeaderboards"] == APILink(href: "/api/v1/game-center/details/gc-1/leaderboards", method: "GET"))
        #expect(detail.apiLinks["listBlockedPlayers"] == APILink(href: "/api/v1/game-center/details/gc-1/blocked-players", method: "GET"))
    }

    @Test func `should show id, app id and arcade status in a table`() {
        let detail = MockRepositoryFactory.makeGameCenterDetail(id: "gc-1", appId: "app-1", isArcadeEnabled: false)
        #expect(GameCenterDetail.tableHeaders == ["ID", "App ID", "Arcade Enabled"])
        #expect(detail.tableRow == ["gc-1", "app-1", "no"])
    }

    @Test func `detail equatable two equal instances`() {
        let a = GameCenterDetail(id: "gc-1", appId: "app-1", isArcadeEnabled: false)
        let b = GameCenterDetail(id: "gc-1", appId: "app-1", isArcadeEnabled: false)
        #expect(a == b)
    }

    @Test func `detail equatable different ids are not equal`() {
        let a = GameCenterDetail(id: "gc-1", appId: "app-1", isArcadeEnabled: false)
        let b = GameCenterDetail(id: "gc-2", appId: "app-1", isArcadeEnabled: false)
        #expect(a != b)
    }

    @Test func `detail codable round trip preserves all fields`() throws {
        let detail = GameCenterDetail(id: "gc-1", appId: "app-42", isArcadeEnabled: true)
        let data = try JSONEncoder().encode(detail)
        let decoded = try JSONDecoder().decode(GameCenterDetail.self, from: data)
        #expect(decoded == detail)
    }
}

// MARK: - GameCenterAchievement

@Suite
struct GameCenterAchievementTests {

    @Test func `achievement carries all fields`() {
        let a = GameCenterAchievement(
            id: "ach-1",
            gameCenterDetailId: "gc-1",
            referenceName: "First Steps",
            vendorIdentifier: "first_steps",
            points: 10,
            isShowBeforeEarned: true,
            isRepeatable: false,
            isArchived: false
        )
        #expect(a.id == "ach-1")
        #expect(a.gameCenterDetailId == "gc-1")
        #expect(a.referenceName == "First Steps")
        #expect(a.vendorIdentifier == "first_steps")
        #expect(a.points == 10)
        #expect(a.isShowBeforeEarned == true)
        #expect(a.isRepeatable == false)
        #expect(a.isArchived == false)
    }

    @Test func `achievement carries gameCenterDetailId`() {
        let a = MockRepositoryFactory.makeGameCenterAchievement(id: "ach-1", gameCenterDetailId: "gc-1")
        #expect(a.gameCenterDetailId == "gc-1")
    }

    @Test func `achievement affordances include list and delete`() {
        let a = MockRepositoryFactory.makeGameCenterAchievement(id: "ach-1", gameCenterDetailId: "gc-1")
        #expect(a.affordances["listAchievements"] == "asc game-center achievements list --detail-id gc-1")
        #expect(a.affordances["delete"] == "asc game-center achievements delete --achievement-id ach-1")
    }

    @Test func `achievement affordances have exactly two keys`() {
        let a = MockRepositoryFactory.makeGameCenterAchievement(id: "ach-1", gameCenterDetailId: "gc-1")
        #expect(a.affordances.count == 2)
    }

    @Test func `achievement equatable two equal instances`() {
        let a = MockRepositoryFactory.makeGameCenterAchievement(id: "ach-1", gameCenterDetailId: "gc-1", points: 10)
        let b = MockRepositoryFactory.makeGameCenterAchievement(id: "ach-1", gameCenterDetailId: "gc-1", points: 10)
        #expect(a == b)
    }

    @Test func `achievement equatable different points are not equal`() {
        let a = MockRepositoryFactory.makeGameCenterAchievement(id: "ach-1", gameCenterDetailId: "gc-1", points: 10)
        let b = MockRepositoryFactory.makeGameCenterAchievement(id: "ach-1", gameCenterDetailId: "gc-1", points: 50)
        #expect(a != b)
    }

    @Test func `achievement codable round trip preserves all fields`() throws {
        let achievement = GameCenterAchievement(
            id: "ach-1", gameCenterDetailId: "gc-1",
            referenceName: "First Steps", vendorIdentifier: "first_steps",
            points: 10, isShowBeforeEarned: true, isRepeatable: false, isArchived: false
        )
        let data = try JSONEncoder().encode(achievement)
        let decoded = try JSONDecoder().decode(GameCenterAchievement.self, from: data)
        #expect(decoded == achievement)
    }
}

// MARK: - GameCenterLeaderboard

@Suite
struct GameCenterLeaderboardTests {

    @Test func `leaderboard carries all fields`() {
        let lb = GameCenterLeaderboard(
            id: "lb-1",
            gameCenterDetailId: "gc-1",
            referenceName: "All Time High",
            vendorIdentifier: "all_time_high",
            scoreSortType: .desc,
            submissionType: .bestScore,
            isArchived: false
        )
        #expect(lb.id == "lb-1")
        #expect(lb.gameCenterDetailId == "gc-1")
        #expect(lb.referenceName == "All Time High")
        #expect(lb.vendorIdentifier == "all_time_high")
        #expect(lb.scoreSortType == .desc)
        #expect(lb.submissionType == .bestScore)
        #expect(lb.isArchived == false)
    }

    @Test func `leaderboard carries gameCenterDetailId`() {
        let lb = MockRepositoryFactory.makeGameCenterLeaderboard(id: "lb-1", gameCenterDetailId: "gc-1")
        #expect(lb.gameCenterDetailId == "gc-1")
    }

    @Test func `leaderboard affordances include list and delete`() {
        let lb = MockRepositoryFactory.makeGameCenterLeaderboard(id: "lb-1", gameCenterDetailId: "gc-1")
        #expect(lb.affordances["listLeaderboards"] == "asc game-center leaderboards list --detail-id gc-1")
        #expect(lb.affordances["delete"] == "asc game-center leaderboards delete --leaderboard-id lb-1")
    }

    @Test func `should offer list, delete and score moderation for a leaderboard`() {
        let lb = MockRepositoryFactory.makeGameCenterLeaderboard(id: "lb-1", gameCenterDetailId: "gc-1")
        #expect(lb.affordances.count == 3)
    }

    @Test func `should point to the scores submitted to the leaderboard`() {
        let lb = MockRepositoryFactory.makeGameCenterLeaderboard(id: "lb-1", gameCenterDetailId: "gc-1")
        #expect(lb.affordances["listScoreModerations"] == "asc game-center score-moderations list --leaderboard-id lb-1")
    }

    @Test func `should link its siblings, delete and scores over REST`() {
        let lb = MockRepositoryFactory.makeGameCenterLeaderboard(id: "lb-1", gameCenterDetailId: "gc-1")
        #expect(lb.apiLinks["listLeaderboards"] == APILink(href: "/api/v1/game-center/details/gc-1/leaderboards", method: "GET"))
        #expect(lb.apiLinks["delete"] == APILink(href: "/api/v1/game-center/leaderboards/lb-1", method: "DELETE"))
        #expect(lb.apiLinks["listScoreModerations"] == APILink(href: "/api/v1/game-center/leaderboards/lb-1/score-moderations", method: "GET"))
    }

    @Test func `should show reference name, vendor id, sort and submission type in a table`() {
        let lb = MockRepositoryFactory.makeGameCenterLeaderboard(
            id: "lb-1", referenceName: "All Time High", vendorIdentifier: "all_time_high",
            scoreSortType: .desc, submissionType: .bestScore
        )
        #expect(GameCenterLeaderboard.tableHeaders == ["ID", "Reference Name", "Vendor ID", "Sort", "Submission"])
        #expect(lb.tableRow == ["lb-1", "All Time High", "all_time_high", "DESC", "BEST_SCORE"])
    }

    @Test func `leaderboard equatable two equal instances`() {
        let a = MockRepositoryFactory.makeGameCenterLeaderboard(id: "lb-1", gameCenterDetailId: "gc-1")
        let b = MockRepositoryFactory.makeGameCenterLeaderboard(id: "lb-1", gameCenterDetailId: "gc-1")
        #expect(a == b)
    }

    @Test func `leaderboard codable round trip preserves all fields`() throws {
        let lb = GameCenterLeaderboard(
            id: "lb-1", gameCenterDetailId: "gc-1",
            referenceName: "All Time High", vendorIdentifier: "all_time",
            scoreSortType: .desc, submissionType: .bestScore, isArchived: false
        )
        let data = try JSONEncoder().encode(lb)
        let decoded = try JSONDecoder().decode(GameCenterLeaderboard.self, from: data)
        #expect(decoded == lb)
    }

    @Test func `score sort type asc has expected raw value`() {
        #expect(ScoreSortType.asc.rawValue == "ASC")
    }

    @Test func `score sort type desc has expected raw value`() {
        #expect(ScoreSortType.desc.rawValue == "DESC")
    }

    @Test func `score sort type init from raw value`() {
        #expect(ScoreSortType(rawValue: "ASC") == .asc)
        #expect(ScoreSortType(rawValue: "DESC") == .desc)
        #expect(ScoreSortType(rawValue: "INVALID") == nil)
    }

    @Test func `submission type best score has expected raw value`() {
        #expect(LeaderboardSubmissionType.bestScore.rawValue == "BEST_SCORE")
    }

    @Test func `submission type most recent score has expected raw value`() {
        #expect(LeaderboardSubmissionType.mostRecentScore.rawValue == "MOST_RECENT_SCORE")
    }

    @Test func `submission type init from raw value`() {
        #expect(LeaderboardSubmissionType(rawValue: "BEST_SCORE") == .bestScore)
        #expect(LeaderboardSubmissionType(rawValue: "MOST_RECENT_SCORE") == .mostRecentScore)
        #expect(LeaderboardSubmissionType(rawValue: "INVALID") == nil)
    }
}
