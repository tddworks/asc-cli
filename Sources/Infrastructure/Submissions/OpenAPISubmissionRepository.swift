@preconcurrency import AppStoreConnect_Swift_SDK
import Domain

public struct OpenAPISubmissionRepository: SubmissionRepository, @unchecked Sendable {
    private let client: any APIClient

    public init(client: any APIClient) {
        self.client = client
    }

    public func submitVersion(versionId: String) async throws -> Domain.ReviewSubmission {
        // Step 1: Fetch the version to extract appId and platform
        let versionReq = APIEndpoint.v1.appStoreVersions.id(versionId).get(
            parameters: .init(include: [.app])
        )
        let versionResp = try await client.request(versionReq)
        guard
            let appId = versionResp.data.relationships?.app?.data?.id,
            let sdkPlatform = versionResp.data.attributes?.platform,
            let platform = Domain.AppStorePlatform(rawValue: sdkPlatform.rawValue)
        else {
            throw APIError.unknown("Failed to extract appId and platform from version \(versionId)")
        }

        // Step 2: Check for an existing open submission (UNRESOLVED_ISSUES or READY_FOR_REVIEW)
        let filterPlatform = APIEndpoint.V1.ReviewSubmissions.GetParameters.FilterPlatform(rawValue: sdkPlatform.rawValue)
        let listReq = APIEndpoint.v1.reviewSubmissions.get(parameters: .init(
            filterPlatform: filterPlatform.map { [$0] },
            filterState: [.unresolvedIssues, .readyForReview],
            filterApp: [appId]
        ))
        let listResp = try await client.request(listReq)
        if let existing = listResp.data.first {
            return try await patchSubmitted(id: existing.id, appId: appId, platform: platform)
        }

        // Step 3: Create new review submission
        let createReq = APIEndpoint.v1.reviewSubmissions.post(
            ReviewSubmissionCreateRequest(
                data: .init(
                    type: .reviewSubmissions,
                    attributes: .init(platform: sdkPlatform),
                    relationships: .init(
                        app: .init(data: .init(type: .apps, id: appId))
                    )
                )
            )
        )
        let submissionResp = try await client.request(createReq)
        let submissionId = submissionResp.data.id

        // Step 4: Add the version as a review submission item
        let itemReq = APIEndpoint.v1.reviewSubmissionItems.post(
            ReviewSubmissionItemCreateRequest(
                data: .init(
                    type: .reviewSubmissionItems,
                    relationships: .init(
                        reviewSubmission: .init(data: .init(type: .reviewSubmissions, id: submissionId)),
                        appStoreVersion: .init(data: .init(type: .appStoreVersions, id: versionId))
                    )
                )
            )
        )
        _ = try await client.request(itemReq)

        // Step 5: Submit for review
        return try await patchSubmitted(id: submissionId, appId: appId, platform: platform)
    }

    public func listSubmissions(
        appId: String,
        states: [Domain.ReviewSubmissionState]?,
        limit: Int?
    ) async throws -> [Domain.ReviewSubmission] {
        let filterState = states?.compactMap {
            APIEndpoint.V1.ReviewSubmissions.GetParameters.FilterState(rawValue: $0.rawValue)
        }
        let request = APIEndpoint.v1.reviewSubmissions.get(parameters: .init(
            filterState: filterState,
            filterApp: [appId],
            limit: limit
        ))
        let response = try await client.request(request)
        return response.data.map { mapListedSubmission($0, appId: appId) }
    }

    private func mapListedSubmission(
        _ sdkSubmission: AppStoreConnect_Swift_SDK.ReviewSubmission,
        appId: String
    ) -> Domain.ReviewSubmission {
        let platform = sdkSubmission.attributes?.platform.flatMap {
            Domain.AppStorePlatform(rawValue: $0.rawValue)
        } ?? .iOS
        let state = sdkSubmission.attributes?.state.flatMap {
            Domain.ReviewSubmissionState(rawValue: $0.rawValue)
        } ?? .readyForReview
        return Domain.ReviewSubmission(
            id: sdkSubmission.id,
            appId: appId,
            platform: platform,
            state: state,
            submittedDate: sdkSubmission.attributes?.submittedDate
        )
    }

    private func patchSubmitted(
        id: String,
        appId: String,
        platform: Domain.AppStorePlatform
    ) async throws -> Domain.ReviewSubmission {
        let submitReq = APIEndpoint.v1.reviewSubmissions.id(id).patch(
            ReviewSubmissionUpdateRequest(
                data: .init(
                    type: .reviewSubmissions,
                    id: id,
                    attributes: .init(isSubmitted: true)
                )
            )
        )
        let finalResp = try await client.request(submitReq)
        return mapSubmission(finalResp.data, appId: appId, platform: platform)
    }

    private func mapSubmission(
        _ sdkSubmission: AppStoreConnect_Swift_SDK.ReviewSubmission,
        appId: String,
        platform: Domain.AppStorePlatform
    ) -> Domain.ReviewSubmission {
        let state = sdkSubmission.attributes?.state.flatMap {
            Domain.ReviewSubmissionState(rawValue: $0.rawValue)
        } ?? .readyForReview
        return Domain.ReviewSubmission(
            id: sdkSubmission.id,
            appId: appId,
            platform: platform,
            state: state,
            submittedDate: sdkSubmission.attributes?.submittedDate
        )
    }
}
