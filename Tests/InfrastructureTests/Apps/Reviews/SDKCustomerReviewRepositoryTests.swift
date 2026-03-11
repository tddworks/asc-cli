@preconcurrency import AppStoreConnect_Swift_SDK
import Testing
@testable import Infrastructure
@testable import Domain

@Suite
struct SDKCustomerReviewRepositoryListReviewsTests {

    @Test func `listReviews injects appId into each review`() async throws {
        let stub = StubAPIClient()
        stub.willReturn(CustomerReviewsResponse(
            data: [
                CustomerReview(type: .customerReviews, id: "rev-1", attributes: .init(rating: 5)),
                CustomerReview(type: .customerReviews, id: "rev-2", attributes: .init(rating: 3)),
            ],
            links: .init(this: "")
        ))

        let repo = SDKCustomerReviewRepository(client: stub)
        let result = try await repo.listReviews(appId: "app-99")

        #expect(result.count == 2)
        #expect(result.allSatisfy { $0.appId == "app-99" })
    }

    @Test func `listReviews maps rating title body and nickname from SDK attributes`() async throws {
        let stub = StubAPIClient()
        stub.willReturn(CustomerReviewsResponse(
            data: [
                CustomerReview(
                    type: .customerReviews,
                    id: "rev-1",
                    attributes: .init(
                        rating: 5,
                        title: "Amazing",
                        body: "Love it",
                        reviewerNickname: "user42"
                    )
                ),
            ],
            links: .init(this: "")
        ))

        let repo = SDKCustomerReviewRepository(client: stub)
        let result = try await repo.listReviews(appId: "app-1")

        #expect(result[0].rating == 5)
        #expect(result[0].title == "Amazing")
        #expect(result[0].body == "Love it")
        #expect(result[0].reviewerNickname == "user42")
    }

    @Test func `listReviews maps territory rawValue from SDK`() async throws {
        let stub = StubAPIClient()
        stub.willReturn(CustomerReviewsResponse(
            data: [
                CustomerReview(
                    type: .customerReviews,
                    id: "rev-1",
                    attributes: .init(rating: 4, territory: .usa)
                ),
            ],
            links: .init(this: "")
        ))

        let repo = SDKCustomerReviewRepository(client: stub)
        let result = try await repo.listReviews(appId: "app-1")

        #expect(result[0].territory == "USA")
    }

    @Test func `listReviews maps nil territory when absent`() async throws {
        let stub = StubAPIClient()
        stub.willReturn(CustomerReviewsResponse(
            data: [
                CustomerReview(type: .customerReviews, id: "rev-1", attributes: .init(rating: 3)),
            ],
            links: .init(this: "")
        ))

        let repo = SDKCustomerReviewRepository(client: stub)
        let result = try await repo.listReviews(appId: "app-1")

        #expect(result[0].territory == nil)
    }
}

@Suite
struct SDKCustomerReviewRepositoryGetReviewTests {

    @Test func `getReview maps review with injected empty appId`() async throws {
        let stub = StubAPIClient()
        stub.willReturn(AppStoreConnect_Swift_SDK.CustomerReviewResponse(
            data: CustomerReview(
                type: .customerReviews,
                id: "rev-42",
                attributes: .init(rating: 5, title: "Wonderful")
            ),
            links: .init(this: "")
        ))

        let repo = SDKCustomerReviewRepository(client: stub)
        let result = try await repo.getReview(reviewId: "rev-42")

        #expect(result.id == "rev-42")
        #expect(result.rating == 5)
        #expect(result.title == "Wonderful")
        #expect(result.appId == "")
    }
}

@Suite
struct SDKCustomerReviewRepositoryGetResponseTests {

    @Test func `getResponse injects reviewId from request parameter`() async throws {
        let stub = StubAPIClient()
        stub.willReturn(CustomerReviewResponseV1Response(
            data: CustomerReviewResponseV1(
                type: .customerReviewResponses,
                id: "resp-1",
                attributes: .init(responseBody: "Thanks!", state: .published)
            ),
            links: .init(this: "")
        ))

        let repo = SDKCustomerReviewRepository(client: stub)
        let result = try await repo.getResponse(reviewId: "rev-42")

        #expect(result.id == "resp-1")
        #expect(result.reviewId == "rev-42")
        #expect(result.responseBody == "Thanks!")
        #expect(result.state == .published)
    }

    @Test func `getResponse maps pendingPublish state`() async throws {
        let stub = StubAPIClient()
        stub.willReturn(CustomerReviewResponseV1Response(
            data: CustomerReviewResponseV1(
                type: .customerReviewResponses,
                id: "resp-1",
                attributes: .init(state: .pendingPublish)
            ),
            links: .init(this: "")
        ))

        let repo = SDKCustomerReviewRepository(client: stub)
        let result = try await repo.getResponse(reviewId: "rev-1")

        #expect(result.state == .pendingPublish)
    }
}

@Suite
struct SDKCustomerReviewRepositoryCreateResponseTests {

    @Test func `createResponse injects reviewId from request parameter`() async throws {
        let stub = StubAPIClient()
        stub.willReturn(CustomerReviewResponseV1Response(
            data: CustomerReviewResponseV1(
                type: .customerReviewResponses,
                id: "resp-new",
                attributes: .init(responseBody: "Thank you!", state: .pendingPublish)
            ),
            links: .init(this: "")
        ))

        let repo = SDKCustomerReviewRepository(client: stub)
        let result = try await repo.createResponse(reviewId: "rev-42", responseBody: "Thank you!")

        #expect(result.id == "resp-new")
        #expect(result.reviewId == "rev-42")
        #expect(result.responseBody == "Thank you!")
        #expect(result.state == .pendingPublish)
    }
}

@Suite
struct SDKCustomerReviewRepositoryDeleteResponseTests {

    @Test func `deleteResponse calls void request`() async throws {
        let stub = StubAPIClient()

        let repo = SDKCustomerReviewRepository(client: stub)
        try await repo.deleteResponse(responseId: "resp-1")

        #expect(stub.voidRequestCalled)
    }
}
