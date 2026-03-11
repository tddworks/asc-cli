@preconcurrency import AppStoreConnect_Swift_SDK
import Domain

public struct SDKCustomerReviewRepository: CustomerReviewRepository, @unchecked Sendable {
    private let client: any APIClient

    public init(client: any APIClient) {
        self.client = client
    }

    public func listReviews(appId: String) async throws -> [Domain.CustomerReview] {
        let request = APIEndpoint.v1.apps.id(appId).customerReviews.get(
            parameters: .init(sort: [.minuscreatedDate])
        )
        let response = try await client.request(request)
        return response.data.map { mapReview($0, appId: appId) }
    }

    public func getReview(reviewId: String) async throws -> Domain.CustomerReview {
        let request = APIEndpoint.v1.customerReviews.id(reviewId).get()
        let response = try await client.request(request)
        return mapReview(response.data, appId: "")
    }

    public func getResponse(reviewId: String) async throws -> Domain.CustomerReviewResponse {
        let request = APIEndpoint.v1.customerReviews.id(reviewId).response.get()
        let response = try await client.request(request)
        return mapResponse(response.data, reviewId: reviewId)
    }

    public func createResponse(reviewId: String, responseBody: String) async throws -> Domain.CustomerReviewResponse {
        let body = CustomerReviewResponseV1CreateRequest(
            data: .init(
                type: .customerReviewResponses,
                attributes: .init(responseBody: responseBody),
                relationships: .init(review: .init(data: .init(type: .customerReviews, id: reviewId)))
            )
        )
        let response = try await client.request(APIEndpoint.v1.customerReviewResponses.post(body))
        return mapResponse(response.data, reviewId: reviewId)
    }

    public func deleteResponse(responseId: String) async throws {
        try await client.request(APIEndpoint.v1.customerReviewResponses.id(responseId).delete)
    }

    // MARK: - Mappers

    private func mapReview(
        _ sdkReview: AppStoreConnect_Swift_SDK.CustomerReview,
        appId: String
    ) -> Domain.CustomerReview {
        Domain.CustomerReview(
            id: sdkReview.id,
            appId: appId,
            rating: sdkReview.attributes?.rating ?? 0,
            title: sdkReview.attributes?.title,
            body: sdkReview.attributes?.body,
            reviewerNickname: sdkReview.attributes?.reviewerNickname,
            createdDate: sdkReview.attributes?.createdDate,
            territory: sdkReview.attributes?.territory?.rawValue
        )
    }

    private func mapResponse(
        _ sdkResponse: AppStoreConnect_Swift_SDK.CustomerReviewResponseV1,
        reviewId: String
    ) -> Domain.CustomerReviewResponse {
        Domain.CustomerReviewResponse(
            id: sdkResponse.id,
            reviewId: reviewId,
            responseBody: sdkResponse.attributes?.responseBody ?? "",
            lastModifiedDate: sdkResponse.attributes?.lastModifiedDate,
            state: mapState(sdkResponse.attributes?.state)
        )
    }

    private func mapState(_ sdkState: AppStoreConnect_Swift_SDK.CustomerReviewResponseV1.Attributes.State?) -> Domain.ReviewResponseState {
        switch sdkState {
        case .published: return .published
        case .pendingPublish: return .pendingPublish
        case .none: return .published
        }
    }
}
