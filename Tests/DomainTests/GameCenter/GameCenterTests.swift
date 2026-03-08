import Foundation
import Testing
@testable import Domain

@Suite
struct GameCenterDetailTests {

    @Test func `detail carries appId`() {
        let detail = MockRepositoryFactory.makeGameCenterDetail(id: "gc-1", appId: "app-1")
        #expect(detail.appId == "app-1")
    }

    @Test func `detail affordances include get, list achievements, list leaderboards`() {
        let detail = MockRepositoryFactory.makeGameCenterDetail(id: "gc-1", appId: "app-1")
        #expect(detail.affordances["getDetail"] == "asc game-center detail get --app-id app-1")
        #expect(detail.affordances["listAchievements"] == "asc game-center achievements list --detail-id gc-1")
        #expect(detail.affordances["listLeaderboards"] == "asc game-center leaderboards list --detail-id gc-1")
    }
}

@Suite
struct GameCenterAchievementTests {

    @Test func `achievement carries gameCenterDetailId`() {
        let a = MockRepositoryFactory.makeGameCenterAchievement(id: "ach-1", gameCenterDetailId: "gc-1")
        #expect(a.gameCenterDetailId == "gc-1")
    }

    @Test func `achievement affordances include list and delete`() {
        let a = MockRepositoryFactory.makeGameCenterAchievement(id: "ach-1", gameCenterDetailId: "gc-1")
        #expect(a.affordances["listAchievements"] == "asc game-center achievements list --detail-id gc-1")
        #expect(a.affordances["delete"] == "asc game-center achievements delete --achievement-id ach-1")
    }
}

@Suite
struct GameCenterLeaderboardTests {

    @Test func `leaderboard carries gameCenterDetailId`() {
        let lb = MockRepositoryFactory.makeGameCenterLeaderboard(id: "lb-1", gameCenterDetailId: "gc-1")
        #expect(lb.gameCenterDetailId == "gc-1")
    }

    @Test func `leaderboard affordances include list and delete`() {
        let lb = MockRepositoryFactory.makeGameCenterLeaderboard(id: "lb-1", gameCenterDetailId: "gc-1")
        #expect(lb.affordances["listLeaderboards"] == "asc game-center leaderboards list --detail-id gc-1")
        #expect(lb.affordances["delete"] == "asc game-center leaderboards delete --leaderboard-id lb-1")
    }

    @Test func `score sort type asc has expected raw value`() {
        #expect(ScoreSortType.asc.rawValue == "ASC")
    }

    @Test func `score sort type desc has expected raw value`() {
        #expect(ScoreSortType.desc.rawValue == "DESC")
    }

    @Test func `submission type best score has expected raw value`() {
        #expect(LeaderboardSubmissionType.bestScore.rawValue == "BEST_SCORE")
    }

    @Test func `submission type most recent score has expected raw value`() {
        #expect(LeaderboardSubmissionType.mostRecentScore.rawValue == "MOST_RECENT_SCORE")
    }
}
