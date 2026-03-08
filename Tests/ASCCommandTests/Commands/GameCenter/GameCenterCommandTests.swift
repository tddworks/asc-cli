import Mockable
import Testing
@testable import ASCCommand
@testable import Domain

@Suite
struct GameCenterDetailGetTests {

    @Test func `detail get table output includes id appId and arcade enabled status`() async throws {
        let mockRepo = MockGameCenterRepository()
        given(mockRepo).getDetail(appId: .any)
            .willReturn(GameCenterDetail(id: "gc-1", appId: "app-1", isArcadeEnabled: false))

        let cmd = try GameCenterDetailGet.parse(["--app-id", "app-1", "--output", "table"])
        let output = try await cmd.execute(repo: mockRepo)

        #expect(output.contains("gc-1"))
        #expect(output.contains("app-1"))
        #expect(output.contains("no"))
    }

    @Test func `detail get returns id, appId, isArcadeEnabled and affordances`() async throws {
        let mockRepo = MockGameCenterRepository()
        given(mockRepo).getDetail(appId: .any)
            .willReturn(GameCenterDetail(id: "gc-1", appId: "app-1", isArcadeEnabled: true))

        let cmd = try GameCenterDetailGet.parse(["--app-id", "app-1", "--pretty"])
        let output = try await cmd.execute(repo: mockRepo)

        #expect(output == """
        {
          "data" : [
            {
              "affordances" : {
                "getDetail" : "asc game-center detail get --app-id app-1",
                "listAchievements" : "asc game-center achievements list --detail-id gc-1",
                "listLeaderboards" : "asc game-center leaderboards list --detail-id gc-1"
              },
              "appId" : "app-1",
              "id" : "gc-1",
              "isArcadeEnabled" : true
            }
          ]
        }
        """)
    }
}

@Suite
struct GameCenterAchievementsListTests {

    @Test func `achievements list returns id, detailId, and affordances`() async throws {
        let mockRepo = MockGameCenterRepository()
        given(mockRepo).listAchievements(gameCenterDetailId: .any)
            .willReturn([
                GameCenterAchievement(
                    id: "ach-1",
                    gameCenterDetailId: "gc-1",
                    referenceName: "First Steps",
                    vendorIdentifier: "first_steps",
                    points: 10,
                    isShowBeforeEarned: true,
                    isRepeatable: false,
                    isArchived: false
                )
            ])

        let cmd = try GameCenterAchievementsList.parse(["--detail-id", "gc-1", "--pretty"])
        let output = try await cmd.execute(repo: mockRepo)

        #expect(output == """
        {
          "data" : [
            {
              "affordances" : {
                "delete" : "asc game-center achievements delete --achievement-id ach-1",
                "listAchievements" : "asc game-center achievements list --detail-id gc-1"
              },
              "gameCenterDetailId" : "gc-1",
              "id" : "ach-1",
              "isArchived" : false,
              "isRepeatable" : false,
              "isShowBeforeEarned" : true,
              "points" : 10,
              "referenceName" : "First Steps",
              "vendorIdentifier" : "first_steps"
            }
          ]
        }
        """)
    }

    @Test func `table output includes achievement fields`() async throws {
        let mockRepo = MockGameCenterRepository()
        given(mockRepo).listAchievements(gameCenterDetailId: .any)
            .willReturn([
                GameCenterAchievement(
                    id: "ach-1",
                    gameCenterDetailId: "gc-1",
                    referenceName: "First Steps",
                    vendorIdentifier: "first_steps",
                    points: 10,
                    isShowBeforeEarned: false,
                    isRepeatable: false,
                    isArchived: false
                )
            ])

        let cmd = try GameCenterAchievementsList.parse(["--detail-id", "gc-1", "--output", "table"])
        let output = try await cmd.execute(repo: mockRepo)

        #expect(output.contains("ach-1"))
        #expect(output.contains("First Steps"))
        #expect(output.contains("first_steps"))
    }
}

@Suite
struct GameCenterAchievementsCreateTests {

    @Test func `achievement create returns created achievement with affordances`() async throws {
        let mockRepo = MockGameCenterRepository()
        given(mockRepo).createAchievement(
            gameCenterDetailId: .any,
            referenceName: .any,
            vendorIdentifier: .any,
            points: .any,
            isShowBeforeEarned: .any,
            isRepeatable: .any
        ).willReturn(GameCenterAchievement(
            id: "ach-new",
            gameCenterDetailId: "gc-1",
            referenceName: "High Score",
            vendorIdentifier: "high_score",
            points: 50,
            isShowBeforeEarned: false,
            isRepeatable: true,
            isArchived: false
        ))

        let cmd = try GameCenterAchievementsCreate.parse([
            "--detail-id", "gc-1",
            "--reference-name", "High Score",
            "--vendor-identifier", "high_score",
            "--points", "50",
            "--repeatable",
            "--pretty",
        ])
        let output = try await cmd.execute(repo: mockRepo)

        #expect(output == """
        {
          "data" : [
            {
              "affordances" : {
                "delete" : "asc game-center achievements delete --achievement-id ach-new",
                "listAchievements" : "asc game-center achievements list --detail-id gc-1"
              },
              "gameCenterDetailId" : "gc-1",
              "id" : "ach-new",
              "isArchived" : false,
              "isRepeatable" : true,
              "isShowBeforeEarned" : false,
              "points" : 50,
              "referenceName" : "High Score",
              "vendorIdentifier" : "high_score"
            }
          ]
        }
        """)
    }
}

@Suite
struct GameCenterAchievementsDeleteTests {

    @Test func `achievement delete calls repo`() async throws {
        let mockRepo = MockGameCenterRepository()
        given(mockRepo).deleteAchievement(id: .any).willReturn(())

        let cmd = try GameCenterAchievementsDelete.parse(["--achievement-id", "ach-1"])
        try await cmd.execute(repo: mockRepo)

        verify(mockRepo).deleteAchievement(id: .value("ach-1")).called(1)
    }
}

@Suite
struct GameCenterLeaderboardsListTests {

    @Test func `table output includes leaderboard fields`() async throws {
        let mockRepo = MockGameCenterRepository()
        given(mockRepo).listLeaderboards(gameCenterDetailId: .any)
            .willReturn([
                GameCenterLeaderboard(
                    id: "lb-1",
                    gameCenterDetailId: "gc-1",
                    referenceName: "All Time High",
                    vendorIdentifier: "all_time_high",
                    scoreSortType: ScoreSortType.desc,
                    submissionType: LeaderboardSubmissionType.bestScore,
                    isArchived: false
                )
            ])

        let cmd = try GameCenterLeaderboardsList.parse(["--detail-id", "gc-1", "--output", "table"])
        let output = try await cmd.execute(repo: mockRepo)

        #expect(output.contains("lb-1"))
        #expect(output.contains("All Time High"))
        #expect(output.contains("DESC"))
        #expect(output.contains("BEST_SCORE"))
    }

    @Test func `leaderboards list returns id, detailId, and affordances`() async throws {
        let mockRepo = MockGameCenterRepository()
        given(mockRepo).listLeaderboards(gameCenterDetailId: .any)
            .willReturn([
                GameCenterLeaderboard(
                    id: "lb-1",
                    gameCenterDetailId: "gc-1",
                    referenceName: "All Time High",
                    vendorIdentifier: "all_time_high",
                    scoreSortType: ScoreSortType.desc,
                    submissionType: LeaderboardSubmissionType.bestScore,
                    isArchived: false
                )
            ])

        let cmd = try GameCenterLeaderboardsList.parse(["--detail-id", "gc-1", "--pretty"])
        let output = try await cmd.execute(repo: mockRepo)

        #expect(output == """
        {
          "data" : [
            {
              "affordances" : {
                "delete" : "asc game-center leaderboards delete --leaderboard-id lb-1",
                "listLeaderboards" : "asc game-center leaderboards list --detail-id gc-1"
              },
              "gameCenterDetailId" : "gc-1",
              "id" : "lb-1",
              "isArchived" : false,
              "referenceName" : "All Time High",
              "scoreSortType" : "DESC",
              "submissionType" : "BEST_SCORE",
              "vendorIdentifier" : "all_time_high"
            }
          ]
        }
        """)
    }
}

@Suite
struct GameCenterLeaderboardsCreateTests {

    @Test func `leaderboard create returns created leaderboard with affordances`() async throws {
        let mockRepo = MockGameCenterRepository()
        given(mockRepo).createLeaderboard(
            gameCenterDetailId: .any,
            referenceName: .any,
            vendorIdentifier: .any,
            scoreSortType: .any,
            submissionType: .any
        ).willReturn(GameCenterLeaderboard(
            id: "lb-new",
            gameCenterDetailId: "gc-1",
            referenceName: "Speed Run",
            vendorIdentifier: "speed_run",
            scoreSortType: ScoreSortType.asc,
            submissionType: LeaderboardSubmissionType.mostRecentScore,
            isArchived: false
        ))

        let cmd = try GameCenterLeaderboardsCreate.parse([
            "--detail-id", "gc-1",
            "--reference-name", "Speed Run",
            "--vendor-identifier", "speed_run",
            "--score-sort-type", "ASC",
            "--submission-type", "MOST_RECENT_SCORE",
            "--pretty",
        ])
        let output = try await cmd.execute(repo: mockRepo)

        #expect(output == """
        {
          "data" : [
            {
              "affordances" : {
                "delete" : "asc game-center leaderboards delete --leaderboard-id lb-new",
                "listLeaderboards" : "asc game-center leaderboards list --detail-id gc-1"
              },
              "gameCenterDetailId" : "gc-1",
              "id" : "lb-new",
              "isArchived" : false,
              "referenceName" : "Speed Run",
              "scoreSortType" : "ASC",
              "submissionType" : "MOST_RECENT_SCORE",
              "vendorIdentifier" : "speed_run"
            }
          ]
        }
        """)
    }
}

@Suite
struct GameCenterLeaderboardsCreateValidationTests {

    @Test func `invalid score sort type throws validation error`() async throws {
        let mockRepo = MockGameCenterRepository()

        let cmd = try GameCenterLeaderboardsCreate.parse([
            "--detail-id", "gc-1",
            "--reference-name", "Test",
            "--vendor-identifier", "test",
            "--score-sort-type", "INVALID",
        ])
        do {
            _ = try await cmd.execute(repo: mockRepo)
            Issue.record("Expected error to be thrown")
        } catch {
            #expect(error.localizedDescription.contains("INVALID") || String(describing: error).contains("INVALID"))
        }
    }

    @Test func `invalid submission type throws validation error`() async throws {
        let mockRepo = MockGameCenterRepository()

        let cmd = try GameCenterLeaderboardsCreate.parse([
            "--detail-id", "gc-1",
            "--reference-name", "Test",
            "--vendor-identifier", "test",
            "--score-sort-type", "DESC",
            "--submission-type", "BAD_VALUE",
        ])
        do {
            _ = try await cmd.execute(repo: mockRepo)
            Issue.record("Expected error to be thrown")
        } catch {
            #expect(error.localizedDescription.contains("BAD_VALUE") || String(describing: error).contains("BAD_VALUE"))
        }
    }
}

@Suite
struct GameCenterLeaderboardsDeleteTests {

    @Test func `leaderboard delete calls repo`() async throws {
        let mockRepo = MockGameCenterRepository()
        given(mockRepo).deleteLeaderboard(id: .any).willReturn(())

        let cmd = try GameCenterLeaderboardsDelete.parse(["--leaderboard-id", "lb-1"])
        try await cmd.execute(repo: mockRepo)

        verify(mockRepo).deleteLeaderboard(id: .value("lb-1")).called(1)
    }
}
