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

        // Step 2: Create review submission for the app + platform
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

        // Step 3: Add the version as a review submission item
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

        // Step 4: Submit for review
        let submitReq = APIEndpoint.v1.reviewSubmissions.id(submissionId).patch(
            ReviewSubmissionUpdateRequest(
                data: .init(
                    type: .reviewSubmissions,
                    id: submissionId,
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
