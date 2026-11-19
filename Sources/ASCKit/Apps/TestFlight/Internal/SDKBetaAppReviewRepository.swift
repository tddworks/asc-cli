@preconcurrency import AppStoreConnect_Swift_SDK

public struct SDKBetaAppReviewRepository: BetaAppReviewRepository, @unchecked Sendable {
    private let client: any APIClient

    public init(client: any APIClient) {
        self.client = client
    }

    public func listSubmissions(buildId: String) async throws -> [ASCKit.BetaAppReviewSubmission] {
        let request = APIEndpoint.v1.betaAppReviewSubmissions.get(parameters: .init(
            filterBuild: [buildId]
        ))
        let response = try await client.request(request)
        return response.data.map { mapSubmission($0, buildId: buildId) }
    }

    public func createSubmission(buildId: String) async throws -> ASCKit.BetaAppReviewSubmission {
        let body = BetaAppReviewSubmissionCreateRequest(data: .init(
            type: .betaAppReviewSubmissions,
            relationships: .init(build: .init(data: .init(type: .builds, id: buildId)))
        ))
        let response = try await client.request(APIEndpoint.v1.betaAppReviewSubmissions.post(body))
        return mapSubmission(response.data, buildId: buildId)
    }

    public func getSubmission(id: String) async throws -> ASCKit.BetaAppReviewSubmission {
        let request = APIEndpoint.v1.betaAppReviewSubmissions.id(id).get()
        let response = try await client.request(request)
        let buildId = response.data.relationships?.build?.data?.id ?? ""
        return mapSubmission(response.data, buildId: buildId)
    }

    public func getDetail(appId: String) async throws -> ASCKit.BetaAppReviewDetail {
        let request = APIEndpoint.v1.betaAppReviewDetails.get(parameters: .init(
            filterApp: [appId]
        ))
        let response = try await client.request(request)
        guard let detail = response.data.first else {
            throw ASCKit.APIError.notFound("No beta app review detail found for app \(appId)")
        }
        return mapDetail(detail, appId: appId)
    }

    public func updateDetail(id: String, update: ASCKit.BetaAppReviewDetailUpdate) async throws -> ASCKit.BetaAppReviewDetail {
        let body = BetaAppReviewDetailUpdateRequest(data: .init(
            type: .betaAppReviewDetails,
            id: id,
            attributes: .init(
                contactFirstName: update.contactFirstName,
                contactLastName: update.contactLastName,
                contactPhone: update.contactPhone,
                contactEmail: update.contactEmail,
                demoAccountName: update.demoAccountName,
                demoAccountPassword: update.demoAccountPassword,
                isDemoAccountRequired: update.demoAccountRequired,
                notes: update.notes
            )
        ))
        let response = try await client.request(APIEndpoint.v1.betaAppReviewDetails.id(id).patch(body))
        let appId = response.data.relationships?.app?.data?.id ?? ""
        return mapDetail(response.data, appId: appId)
    }

    // MARK: - Mappers

    private func mapSubmission(_ sdk: AppStoreConnect_Swift_SDK.BetaAppReviewSubmission, buildId: String) -> ASCKit.BetaAppReviewSubmission {
        ASCKit.BetaAppReviewSubmission(
            id: sdk.id,
            buildId: buildId,
            state: mapState(sdk.attributes?.betaReviewState),
            submittedDate: sdk.attributes?.submittedDate
        )
    }

    private func mapState(_ state: AppStoreConnect_Swift_SDK.BetaReviewState?) -> ASCKit.BetaReviewState {
        guard let state else { return .waitingForReview }
        switch state {
        case .waitingForReview: return .waitingForReview
        case .inReview: return .inReview
        case .rejected: return .rejected
        case .approved: return .approved
        }
    }

    private func mapDetail(_ sdk: AppStoreConnect_Swift_SDK.BetaAppReviewDetail, appId: String) -> ASCKit.BetaAppReviewDetail {
        ASCKit.BetaAppReviewDetail(
            id: sdk.id,
            appId: appId,
            contactFirstName: sdk.attributes?.contactFirstName,
            contactLastName: sdk.attributes?.contactLastName,
            contactPhone: sdk.attributes?.contactPhone,
            contactEmail: sdk.attributes?.contactEmail,
            demoAccountName: sdk.attributes?.demoAccountName,
            demoAccountPassword: sdk.attributes?.demoAccountPassword,
            demoAccountRequired: sdk.attributes?.isDemoAccountRequired ?? false,
            notes: sdk.attributes?.notes
        )
    }
}
