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
            // A refused submit leaves its draft open and empty, so it may not contain this version yet.
            let items = try await listSubmissionItems(submissionId: existing.id)
            if !items.contains(where: { $0.linkedResourceId == versionId }) {
                _ = try await addItem(submissionId: existing.id, target: .appStoreVersion(versionId))
            }
            return try await patchSubmitted(id: existing.id, appId: appId, platform: platform)
        }

        // Step 3: Create new review submission
        let submissionResp = try await explainingRefusal {
            try await client.request(APIEndpoint.v1.reviewSubmissions.post(
                ReviewSubmissionCreateRequest(
                    data: .init(
                        type: .reviewSubmissions,
                        attributes: .init(platform: sdkPlatform),
                        relationships: .init(
                            app: .init(data: .init(type: .apps, id: appId))
                        )
                    )
                )
            ))
        }
        let submissionId = submissionResp.data.id

        // Step 4: Add the version as a review submission item
        _ = try await addItem(submissionId: submissionId, target: .appStoreVersion(versionId))

        // Step 5: Submit for review
        return try await patchSubmitted(id: submissionId, appId: appId, platform: platform)
    }

    public func createSubmission(appId: String, platform: Domain.AppStorePlatform) async throws -> Domain.ReviewSubmission {
        guard let sdkPlatform = AppStoreConnect_Swift_SDK.Platform(rawValue: platform.rawValue) else {
            throw APIError.unknown("Unsupported review submission platform \(platform.rawValue)")
        }
        let listResp = try await client.request(APIEndpoint.v1.reviewSubmissions.get(parameters: .init(
            filterPlatform: APIEndpoint.V1.ReviewSubmissions.GetParameters.FilterPlatform(rawValue: platform.rawValue).map { [$0] },
            filterState: [.unresolvedIssues, .readyForReview],
            filterApp: [appId]
        )))
        if let open = listResp.data.first {
            return mapListedSubmission(open, appId: appId)
        }
        let created = try await client.request(APIEndpoint.v1.reviewSubmissions.post(
            ReviewSubmissionCreateRequest(data: .init(
                type: .reviewSubmissions,
                attributes: .init(platform: sdkPlatform),
                relationships: .init(app: .init(data: .init(type: .apps, id: appId)))
            ))
        ))
        return mapListedSubmission(created.data, appId: appId)
    }

    public func addItem(submissionId: String, target: Domain.ReviewItemTarget) async throws -> Domain.ReviewSubmissionItem {
        var relationships = ReviewSubmissionItemCreateRequest.Data.Relationships(
            reviewSubmission: .init(data: .init(type: .reviewSubmissions, id: submissionId))
        )
        switch target {
        case .appStoreVersion(let id):
            relationships.appStoreVersion = .init(data: .init(type: .appStoreVersions, id: id))
        case .inAppPurchaseVersion(let id):
            relationships.inAppPurchaseVersion = .init(data: .init(type: .inAppPurchaseVersions, id: id))
        case .subscriptionVersion(let id):
            relationships.subscriptionVersion = .init(data: .init(type: .subscriptionVersions, id: id))
        case .subscriptionGroupVersion(let id):
            relationships.subscriptionGroupVersion = .init(data: .init(type: .subscriptionGroupVersions, id: id))
        }
        let response = try await explainingRefusal {
            try await client.request(APIEndpoint.v1.reviewSubmissionItems.post(
                ReviewSubmissionItemCreateRequest(data: .init(type: .reviewSubmissionItems, relationships: relationships))
            ))
        }
        // Apple's create response omits the relationship, so the target supplies it.
        let item = mapSubmissionItem(response.data, submissionId: submissionId)
        return Domain.ReviewSubmissionItem(
            id: item.id, submissionId: submissionId, state: item.state,
            linkedResourceId: target.id, linkedResourceType: target.linkedResource
        )
    }

    public func removeItem(itemId: String) async throws {
        try await client.request(APIEndpoint.v1.reviewSubmissionItems.id(itemId).delete)
    }

    public func submit(submissionId: String) async throws -> Domain.ReviewSubmission {
        _ = try await explainingRefusal {
            try await client.request(APIEndpoint.v1.reviewSubmissions.id(submissionId).patch(
                ReviewSubmissionUpdateRequest(data: .init(
                    type: .reviewSubmissions, id: submissionId, attributes: .init(isSubmitted: true)
                ))
            ))
        }
        // The PATCH response doesn't carry the app relationship — re-read it.
        return try await getSubmission(id: submissionId)
    }

    public func getSubmission(id: String) async throws -> Domain.ReviewSubmission {
        let request = APIEndpoint.v1.reviewSubmissions.id(id).get(parameters: .init(
            include: [.app]
        ))
        let response = try await client.request(request)
        let appId = response.data.relationships?.app?.data?.id ?? ""
        return mapListedSubmission(response.data, appId: appId)
    }

    public func listSubmissionItems(submissionId: String) async throws -> [Domain.ReviewSubmissionItem] {
        // `include` makes Apple return each item's relationship linkage, which the mapper
        // reads to report what the item points at.
        let request = APIEndpoint.v1.reviewSubmissions.id(submissionId).items.get(parameters: .init(
            include: [
                .appStoreVersion, .appCustomProductPageVersion,
                .appStoreVersionExperimentV2, .appEvent, .backgroundAssetVersion,
                .gameCenterAchievementVersion, .gameCenterActivityVersion, .gameCenterChallengeVersion,
                .gameCenterLeaderboardSetVersion, .gameCenterLeaderboardVersion,
                .inAppPurchaseVersion, .subscriptionVersion, .subscriptionGroupVersion,
            ]
        ))
        let response = try await client.request(request)
        return response.data.map { mapSubmissionItem($0, submissionId: submissionId) }
    }

    private func mapSubmissionItem(
        _ sdkItem: AppStoreConnect_Swift_SDK.ReviewSubmissionItem,
        submissionId: String
    ) -> Domain.ReviewSubmissionItem {
        let state = sdkItem.attributes?.state.flatMap {
            Domain.ReviewSubmissionItemState(rawValue: $0.rawValue)
        } ?? .readyForReview

        // Apple attaches exactly one related resource per item, expressed as
        // separate optional relationships. Probe the well-known kinds in priority
        // order — appStoreVersion first since it's by far the common case.
        let (linkedId, linkedType): (String?, Domain.ReviewSubmissionItemLinkedResource?) = {
            if let id = sdkItem.relationships?.appStoreVersion?.data?.id { return (id, .appStoreVersion) }
            if let id = sdkItem.relationships?.appCustomProductPageVersion?.data?.id { return (id, .appCustomProductPageVersion) }
            if let id = sdkItem.relationships?.appStoreVersionExperiment?.data?.id { return (id, .appStoreVersionExperiment) }
            if let id = sdkItem.relationships?.appStoreVersionExperimentV2?.data?.id { return (id, .appStoreVersionExperiment) }
            if let id = sdkItem.relationships?.appEvent?.data?.id { return (id, .appEvent) }
            if let id = sdkItem.relationships?.backgroundAssetVersion?.data?.id { return (id, .backgroundAssetVersion) }
            if let id = sdkItem.relationships?.gameCenterAchievementVersion?.data?.id { return (id, .gameCenterAchievementVersion) }
            if let id = sdkItem.relationships?.gameCenterActivityVersion?.data?.id { return (id, .gameCenterActivityVersion) }
            if let id = sdkItem.relationships?.gameCenterChallengeVersion?.data?.id { return (id, .gameCenterChallengeVersion) }
            if let id = sdkItem.relationships?.gameCenterLeaderboardSetVersion?.data?.id { return (id, .gameCenterLeaderboardSetVersion) }
            if let id = sdkItem.relationships?.gameCenterLeaderboardVersion?.data?.id { return (id, .gameCenterLeaderboardVersion) }
            if let id = sdkItem.relationships?.inAppPurchaseVersion?.data?.id { return (id, .inAppPurchaseVersion) }
            if let id = sdkItem.relationships?.subscriptionVersion?.data?.id { return (id, .subscriptionVersion) }
            if let id = sdkItem.relationships?.subscriptionGroupVersion?.data?.id { return (id, .subscriptionGroupVersion) }
            return (nil, nil)
        }()

        return Domain.ReviewSubmissionItem(
            id: sdkItem.id,
            submissionId: submissionId,
            state: state,
            linkedResourceId: linkedId,
            linkedResourceType: linkedType
        )
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
        let finalResp = try await explainingRefusal { try await client.request(submitReq) }
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

    /// Apple's refusals carry a generic headline ("please check associated errors") and
    /// put the actual reasons in `meta.associatedErrors`, which the SDK's error text drops.
    /// Surface them so the user knows what to fix.
    private func explainingRefusal<T>(_ request: () async throws -> T) async throws -> T {
        do {
            return try await request()
        } catch APIProvider.Error.requestFailure(let status, let response?, _) where (400..<500).contains(status) {
            guard let first = response.errors?.first else { throw APIError.unknown("\(response)") }
            let reasons = (response.errors ?? [])
                .compactMap { $0.meta?.associatedErrors }
                .flatMap { $0.sorted(by: { $0.key < $1.key }).flatMap(\.value) }
                .map { $0.detail ?? $0.title }
            throw ReviewSubmissionError.refused(message: first.detail ?? first.title, reasons: reasons)
        }
    }
}
