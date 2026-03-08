@preconcurrency import AppStoreConnect_Swift_SDK
import Testing
@testable import Infrastructure
@testable import Domain

@Suite
struct SDKGameCenterRepositoryTests {

    // MARK: - getDetail

    @Test func `getDetail injects appId from request parameter`() async throws {
        let stub = StubAPIClient()
        stub.willReturn(GameCenterDetailResponse(
            data: GameCenterDetail(
                type: .gameCenterDetails,
                id: "gc-99",
                attributes: .init(isArcadeEnabled: true)
            ),
            links: .init(this: "")
        ))

        let repo = SDKGameCenterRepository(client: stub)
        let detail = try await repo.getDetail(appId: "app-42")

        #expect(detail.id == "gc-99")
        #expect(detail.appId == "app-42")
        #expect(detail.isArcadeEnabled == true)
    }

    @Test func `getDetail defaults isArcadeEnabled to false when nil`() async throws {
        let stub = StubAPIClient()
        stub.willReturn(GameCenterDetailResponse(
            data: GameCenterDetail(
                type: .gameCenterDetails,
                id: "gc-1",
                attributes: .init(isArcadeEnabled: nil)
            ),
            links: .init(this: "")
        ))

        let repo = SDKGameCenterRepository(client: stub)
        let detail = try await repo.getDetail(appId: "app-1")

        #expect(detail.isArcadeEnabled == false)
    }

    // MARK: - listAchievements

    @Test func `listAchievements injects gameCenterDetailId from parameter`() async throws {
        let stub = StubAPIClient()
        stub.willReturn(GameCenterAchievementsResponse(
            data: [
                GameCenterAchievement(
                    type: .gameCenterAchievements,
                    id: "ach-1",
                    attributes: .init(
                        referenceName: "First Steps",
                        vendorIdentifier: "first_steps",
                        points: 10,
                        isShowBeforeEarned: true,
                        isRepeatable: false,
                        isArchived: false
                    )
                ),
            ],
            links: .init(this: "")
        ))

        let repo = SDKGameCenterRepository(client: stub)
        let result = try await repo.listAchievements(gameCenterDetailId: "gc-42")

        #expect(result[0].id == "ach-1")
        #expect(result[0].gameCenterDetailId == "gc-42")
        #expect(result[0].referenceName == "First Steps")
        #expect(result[0].vendorIdentifier == "first_steps")
        #expect(result[0].points == 10)
        #expect(result[0].isShowBeforeEarned == true)
        #expect(result[0].isRepeatable == false)
        #expect(result[0].isArchived == false)
    }

    // MARK: - createAchievement

    @Test func `createAchievement maps response and injects detailId`() async throws {
        let stub = StubAPIClient()
        stub.willReturn(GameCenterAchievementResponse(
            data: GameCenterAchievement(
                type: .gameCenterAchievements,
                id: "ach-new",
                attributes: .init(
                    referenceName: "High Score",
                    vendorIdentifier: "high_score",
                    points: 50,
                    isShowBeforeEarned: false,
                    isRepeatable: true,
                    isArchived: false
                )
            ),
            links: .init(this: "")
        ))

        let repo = SDKGameCenterRepository(client: stub)
        let result = try await repo.createAchievement(
            gameCenterDetailId: "gc-1",
            referenceName: "High Score",
            vendorIdentifier: "high_score",
            points: 50,
            isShowBeforeEarned: false,
            isRepeatable: true
        )

        #expect(result.id == "ach-new")
        #expect(result.gameCenterDetailId == "gc-1")
        #expect(result.points == 50)
        #expect(result.isRepeatable == true)
    }

    // MARK: - deleteAchievement

    @Test func `deleteAchievement calls void request`() async throws {
        let stub = StubAPIClient()

        let repo = SDKGameCenterRepository(client: stub)
        try await repo.deleteAchievement(id: "ach-1")

        #expect(stub.voidRequestCalled == true)
    }

    // MARK: - listLeaderboards

    @Test func `listLeaderboards injects gameCenterDetailId from parameter`() async throws {
        let stub = StubAPIClient()
        stub.willReturn(GameCenterLeaderboardsResponse(
            data: [
                GameCenterLeaderboard(
                    type: .gameCenterLeaderboards,
                    id: "lb-1",
                    attributes: .init(
                        defaultFormatter: .integer,
                        referenceName: "All Time High",
                        vendorIdentifier: "all_time_high",
                        submissionType: .bestScore,
                        scoreSortType: .desc,
                        isArchived: false
                    )
                ),
            ],
            links: .init(this: "")
        ))

        let repo = SDKGameCenterRepository(client: stub)
        let result = try await repo.listLeaderboards(gameCenterDetailId: "gc-42")

        #expect(result[0].id == "lb-1")
        #expect(result[0].gameCenterDetailId == "gc-42")
        #expect(result[0].referenceName == "All Time High")
        #expect(result[0].vendorIdentifier == "all_time_high")
        #expect(result[0].scoreSortType == .desc)
        #expect(result[0].submissionType == .bestScore)
        #expect(result[0].isArchived == false)
    }

    // MARK: - createLeaderboard

    @Test func `createLeaderboard maps response and injects detailId`() async throws {
        let stub = StubAPIClient()
        stub.willReturn(GameCenterLeaderboardResponse(
            data: GameCenterLeaderboard(
                type: .gameCenterLeaderboards,
                id: "lb-new",
                attributes: .init(
                    defaultFormatter: .integer,
                    referenceName: "Speed Run",
                    vendorIdentifier: "speed_run",
                    submissionType: .mostRecentScore,
                    scoreSortType: .asc,
                    isArchived: false
                )
            ),
            links: .init(this: "")
        ))

        let repo = SDKGameCenterRepository(client: stub)
        let result = try await repo.createLeaderboard(
            gameCenterDetailId: "gc-1",
            referenceName: "Speed Run",
            vendorIdentifier: "speed_run",
            scoreSortType: .asc,
            submissionType: .mostRecentScore
        )

        #expect(result.id == "lb-new")
        #expect(result.gameCenterDetailId == "gc-1")
        #expect(result.scoreSortType == .asc)
        #expect(result.submissionType == .mostRecentScore)
    }

    // MARK: - deleteLeaderboard

    @Test func `deleteLeaderboard calls void request`() async throws {
        let stub = StubAPIClient()

        let repo = SDKGameCenterRepository(client: stub)
        try await repo.deleteLeaderboard(id: "lb-1")

        #expect(stub.voidRequestCalled == true)
    }
}
