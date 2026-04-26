@preconcurrency import AppStoreConnect_Swift_SDK
import Testing
@testable import Infrastructure
@testable import Domain

@Suite
struct SDKSubscriptionReviewRepositoryTests {

    @Test func `deleteReviewScreenshot performs void request`() async throws {
        let stub = StubAPIClient()
        let repo = SDKSubscriptionReviewRepository(client: stub)
        try await repo.deleteReviewScreenshot(screenshotId: "rs-1")
        #expect(stub.voidRequestCalled == true)
    }
}
