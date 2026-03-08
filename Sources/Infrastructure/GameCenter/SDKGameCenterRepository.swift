@preconcurrency import AppStoreConnect_Swift_SDK
import Domain

public struct SDKGameCenterRepository: GameCenterRepository, @unchecked Sendable {
    private let client: any APIClient

    public init(client: any APIClient) {
        self.client = client
    }

    // MARK: - Detail

    public func getDetail(appId: String) async throws -> Domain.GameCenterDetail {
        let request = APIEndpoint.v1.apps.id(appId).gameCenterDetail.get()
        let response = try await client.request(request)
        return mapDetail(response.data, appId: appId)
    }

    // MARK: - Achievements

    public func listAchievements(gameCenterDetailId: String) async throws -> [Domain.GameCenterAchievement] {
        let request = APIEndpoint.v1.gameCenterDetails.id(gameCenterDetailId).gameCenterAchievements.get()
        let response = try await client.request(request)
        return response.data.map { mapAchievement($0, gameCenterDetailId: gameCenterDetailId) }
    }

    public func createAchievement(
        gameCenterDetailId: String,
        referenceName: String,
        vendorIdentifier: String,
        points: Int,
        isShowBeforeEarned: Bool,
        isRepeatable: Bool
    ) async throws -> Domain.GameCenterAchievement {
        let body = GameCenterAchievementCreateRequest(data: .init(
            type: .gameCenterAchievements,
            attributes: .init(
                referenceName: referenceName,
                vendorIdentifier: vendorIdentifier,
                points: points,
                isShowBeforeEarned: isShowBeforeEarned,
                isRepeatable: isRepeatable
            ),
            relationships: .init(
                gameCenterDetail: .init(data: .init(type: .gameCenterDetails, id: gameCenterDetailId))
            )
        ))
        let response = try await client.request(APIEndpoint.v1.gameCenterAchievements.post(body))
        return mapAchievement(response.data, gameCenterDetailId: gameCenterDetailId)
    }

    public func deleteAchievement(id: String) async throws {
        try await client.request(APIEndpoint.v1.gameCenterAchievements.id(id).delete)
    }

    // MARK: - Leaderboards

    public func listLeaderboards(gameCenterDetailId: String) async throws -> [Domain.GameCenterLeaderboard] {
        let request = APIEndpoint.v1.gameCenterDetails.id(gameCenterDetailId).gameCenterLeaderboards.get()
        let response = try await client.request(request)
        return response.data.map { mapLeaderboard($0, gameCenterDetailId: gameCenterDetailId) }
    }

    public func createLeaderboard(
        gameCenterDetailId: String,
        referenceName: String,
        vendorIdentifier: String,
        scoreSortType: Domain.ScoreSortType,
        submissionType: Domain.LeaderboardSubmissionType
    ) async throws -> Domain.GameCenterLeaderboard {
        let body = GameCenterLeaderboardCreateRequest(data: .init(
            type: .gameCenterLeaderboards,
            attributes: .init(
                defaultFormatter: .integer,
                referenceName: referenceName,
                vendorIdentifier: vendorIdentifier,
                submissionType: mapSubmissionTypeForCreate(submissionType),
                scoreSortType: mapScoreSortTypeForCreate(scoreSortType)
            ),
            relationships: .init(
                gameCenterDetail: .init(data: .init(type: .gameCenterDetails, id: gameCenterDetailId))
            )
        ))
        let response = try await client.request(APIEndpoint.v1.gameCenterLeaderboards.post(body))
        return mapLeaderboard(response.data, gameCenterDetailId: gameCenterDetailId)
    }

    public func deleteLeaderboard(id: String) async throws {
        try await client.request(APIEndpoint.v1.gameCenterLeaderboards.id(id).delete)
    }

    // MARK: - Mappers

    private func mapDetail(_ sdk: AppStoreConnect_Swift_SDK.GameCenterDetail, appId: String) -> Domain.GameCenterDetail {
        Domain.GameCenterDetail(
            id: sdk.id,
            appId: appId,
            isArcadeEnabled: sdk.attributes?.isArcadeEnabled ?? false
        )
    }

    private func mapAchievement(
        _ sdk: AppStoreConnect_Swift_SDK.GameCenterAchievement,
        gameCenterDetailId: String
    ) -> Domain.GameCenterAchievement {
        Domain.GameCenterAchievement(
            id: sdk.id,
            gameCenterDetailId: gameCenterDetailId,
            referenceName: sdk.attributes?.referenceName ?? "",
            vendorIdentifier: sdk.attributes?.vendorIdentifier ?? "",
            points: sdk.attributes?.points ?? 0,
            isShowBeforeEarned: sdk.attributes?.isShowBeforeEarned ?? false,
            isRepeatable: sdk.attributes?.isRepeatable ?? false,
            isArchived: sdk.attributes?.isArchived ?? false
        )
    }

    private func mapLeaderboard(
        _ sdk: AppStoreConnect_Swift_SDK.GameCenterLeaderboard,
        gameCenterDetailId: String
    ) -> Domain.GameCenterLeaderboard {
        Domain.GameCenterLeaderboard(
            id: sdk.id,
            gameCenterDetailId: gameCenterDetailId,
            referenceName: sdk.attributes?.referenceName ?? "",
            vendorIdentifier: sdk.attributes?.vendorIdentifier ?? "",
            scoreSortType: mapScoreSortTypeFromSDK(sdk.attributes?.scoreSortType),
            submissionType: mapSubmissionTypeFromSDK(sdk.attributes?.submissionType),
            isArchived: sdk.attributes?.isArchived ?? false
        )
    }

    private func mapScoreSortTypeForCreate(_ type: Domain.ScoreSortType) -> AppStoreConnect_Swift_SDK.GameCenterLeaderboardCreateRequest.Data.Attributes.ScoreSortType {
        switch type {
        case .asc: return .asc
        case .desc: return .desc
        }
    }

    private func mapScoreSortTypeFromSDK(_ type: AppStoreConnect_Swift_SDK.GameCenterLeaderboard.Attributes.ScoreSortType?) -> Domain.ScoreSortType {
        switch type {
        case .asc: return .asc
        case .desc, .none: return .desc
        }
    }

    private func mapSubmissionTypeForCreate(_ type: Domain.LeaderboardSubmissionType) -> AppStoreConnect_Swift_SDK.GameCenterLeaderboardCreateRequest.Data.Attributes.SubmissionType {
        switch type {
        case .bestScore: return .bestScore
        case .mostRecentScore: return .mostRecentScore
        }
    }

    private func mapSubmissionTypeFromSDK(_ type: AppStoreConnect_Swift_SDK.GameCenterLeaderboard.Attributes.SubmissionType?) -> Domain.LeaderboardSubmissionType {
        switch type {
        case .bestScore, .none: return .bestScore
        case .mostRecentScore: return .mostRecentScore
        }
    }
}
