@preconcurrency import AppStoreConnect_Swift_SDK
import Testing
@testable import Infrastructure
@testable import Domain

@Suite
struct SDKInAppPurchaseSubmissionRepositoryTests {

    @Test func `submitInAppPurchase injects iapId into result`() async throws {
        let stub = StubAPIClient()
        stub.willReturn(InAppPurchaseSubmissionResponse(
            data: InAppPurchaseSubmission(type: .inAppPurchaseSubmissions, id: "sub-1"),
            links: .init(this: "")
        ))

        let repo = SDKInAppPurchaseSubmissionRepository(client: stub)
        let result = try await repo.submitInAppPurchase(iapId: "iap-abc")

        #expect(result.id == "sub-1")
        #expect(result.iapId == "iap-abc")
    }

    @Test func `deleteSubmission performs void request via manual DELETE`() async throws {
        let stub = StubAPIClient()
        let repo = SDKInAppPurchaseSubmissionRepository(client: stub)
        try await repo.deleteSubmission(submissionId: "sub-1")
        #expect(stub.voidRequestCalled == true)
    }
}
