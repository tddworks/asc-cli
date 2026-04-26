@preconcurrency import AppStoreConnect_Swift_SDK
import Testing
@testable import Infrastructure
@testable import Domain

@Suite
struct SDKSubscriptionSubmissionRepositoryTests {

    @Test func `submitSubscription injects subscriptionId into result`() async throws {
        let stub = StubAPIClient()
        stub.willReturn(SubscriptionSubmissionResponse(
            data: AppStoreConnect_Swift_SDK.SubscriptionSubmission(
                type: .subscriptionSubmissions,
                id: "submit-1"
            ),
            links: .init(this: "")
        ))

        let repo = SDKSubscriptionSubmissionRepository(client: stub)
        let result = try await repo.submitSubscription(subscriptionId: "sub-abc")

        #expect(result.id == "submit-1")
        #expect(result.subscriptionId == "sub-abc")
    }

    @Test func `deleteSubmission performs void request via manual DELETE`() async throws {
        let stub = StubAPIClient()
        let repo = SDKSubscriptionSubmissionRepository(client: stub)
        try await repo.deleteSubmission(submissionId: "sub-1")
        #expect(stub.voidRequestCalled == true)
    }
}
