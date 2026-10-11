import Mockable
import Testing
@testable import ASCCommand
@testable import Domain

@Suite
struct GameCenterControllerTests {

    /// Stubs App Store Connect so the created achievement echoes what it was sent.
    private func achievementEchoingRepo() -> MockGameCenterRepository {
        let mockRepo = MockGameCenterRepository()
        given(mockRepo).createAchievement(
            gameCenterDetailId: .any, referenceName: .any, vendorIdentifier: .any,
            points: .any, isShowBeforeEarned: .any, isRepeatable: .any
        ).willProduce { detailId, referenceName, vendorIdentifier, points, isShowBeforeEarned, isRepeatable in
            GameCenterAchievement(
                id: "ach-1", gameCenterDetailId: detailId, referenceName: referenceName,
                vendorIdentifier: vendorIdentifier, points: points,
                isShowBeforeEarned: isShowBeforeEarned, isRepeatable: isRepeatable, isArchived: false
            )
        }
        return mockRepo
    }

    /// Stubs App Store Connect so the created leaderboard echoes what it was sent.
    private func leaderboardEchoingRepo() -> MockGameCenterRepository {
        let mockRepo = MockGameCenterRepository()
        given(mockRepo).createLeaderboard(
            gameCenterDetailId: .any, referenceName: .any, vendorIdentifier: .any,
            scoreSortType: .any, submissionType: .any
        ).willProduce { detailId, referenceName, vendorIdentifier, scoreSortType, submissionType in
            GameCenterLeaderboard(
                id: "lb-1", gameCenterDetailId: detailId, referenceName: referenceName,
                vendorIdentifier: vendorIdentifier, scoreSortType: scoreSortType,
                submissionType: submissionType, isArchived: false
            )
        }
        return mockRepo
    }

    // MARK: - Achievements

    @Test func `should create an achievement over REST with the same fields as the CLI`() async throws {
        let created = try await GameCenterController.createAchievement(
            detailId: "gc-1",
            json: [
                "referenceName": "First Win", "vendorIdentifier": "com.example.first-win",
                "points": 10, "showBeforeEarned": true, "repeatable": true,
            ],
            repo: achievementEchoingRepo()
        )

        #expect(created == GameCenterAchievement(
            id: "ach-1", gameCenterDetailId: "gc-1", referenceName: "First Win",
            vendorIdentifier: "com.example.first-win", points: 10,
            isShowBeforeEarned: true, isRepeatable: true, isArchived: false
        ))
    }

    @Test func `should create a hidden one-time achievement when REST leaves out showBeforeEarned and repeatable`() async throws {
        let created = try await GameCenterController.createAchievement(
            detailId: "gc-1",
            json: ["referenceName": "First Win", "vendorIdentifier": "com.example.first-win", "points": 10],
            repo: achievementEchoingRepo()
        )

        #expect(created == GameCenterAchievement(
            id: "ach-1", gameCenterDetailId: "gc-1", referenceName: "First Win",
            vendorIdentifier: "com.example.first-win", points: 10,
            isShowBeforeEarned: false, isRepeatable: false, isArchived: false
        ))
    }

    @Test func `should refuse a REST achievement without its points`() async throws {
        await #expect(throws: GameCenterController.BadRequest("Provide referenceName, vendorIdentifier and points")) {
            _ = try await GameCenterController.createAchievement(
                detailId: "gc-1",
                json: ["referenceName": "First Win", "vendorIdentifier": "com.example.first-win"],
                repo: MockGameCenterRepository()
            )
        }
    }

    // MARK: - Leaderboards

    @Test func `should create a leaderboard over REST with the same fields as the CLI`() async throws {
        let created = try await GameCenterController.createLeaderboard(
            detailId: "gc-1",
            json: [
                "referenceName": "All Time High", "vendorIdentifier": "com.example.high-score",
                "scoreSortType": "DESC", "submissionType": "MOST_RECENT_SCORE",
            ],
            repo: leaderboardEchoingRepo()
        )

        #expect(created == GameCenterLeaderboard(
            id: "lb-1", gameCenterDetailId: "gc-1", referenceName: "All Time High",
            vendorIdentifier: "com.example.high-score", scoreSortType: .desc,
            submissionType: .mostRecentScore, isArchived: false
        ))
    }

    @Test func `should keep each player's best score when REST leaves out submissionType`() async throws {
        let created = try await GameCenterController.createLeaderboard(
            detailId: "gc-1",
            json: ["referenceName": "All Time High", "vendorIdentifier": "com.example.high-score", "scoreSortType": "asc"],
            repo: leaderboardEchoingRepo()
        )

        #expect(created == GameCenterLeaderboard(
            id: "lb-1", gameCenterDetailId: "gc-1", referenceName: "All Time High",
            vendorIdentifier: "com.example.high-score", scoreSortType: .asc,
            submissionType: .bestScore, isArchived: false
        ))
    }

    @Test func `should refuse a REST leaderboard with an unknown score sort order`() async throws {
        await #expect(throws: GameCenterController.BadRequest("Provide referenceName, vendorIdentifier and scoreSortType (ASC or DESC)")) {
            _ = try await GameCenterController.createLeaderboard(
                detailId: "gc-1",
                json: ["referenceName": "All Time High", "vendorIdentifier": "com.example.high-score", "scoreSortType": "SIDEWAYS"],
                repo: MockGameCenterRepository()
            )
        }
    }

    @Test func `should refuse a REST leaderboard with an unknown submission type`() async throws {
        await #expect(throws: GameCenterController.BadRequest("submissionType must be BEST_SCORE or MOST_RECENT_SCORE")) {
            _ = try await GameCenterController.createLeaderboard(
                detailId: "gc-1",
                json: [
                    "referenceName": "All Time High", "vendorIdentifier": "com.example.high-score",
                    "scoreSortType": "DESC", "submissionType": "AVERAGE_SCORE",
                ],
                repo: MockGameCenterRepository()
            )
        }
    }
}
