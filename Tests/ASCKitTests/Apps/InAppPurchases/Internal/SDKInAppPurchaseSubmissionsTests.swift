@preconcurrency import AppStoreConnect_Swift_SDK
import Testing
@testable import ASCKit

@Suite
struct SDKInAppPurchaseSubmissionsTests {

    @Test func `submitInAppPurchase injects iapId into result`() async throws {
        let stub = StubAPIClient()
        stub.willReturn(InAppPurchaseSubmissionResponse(
            data: InAppPurchaseSubmission(type: .inAppPurchaseSubmissions, id: "sub-1"),
            links: .init(this: "")
        ))

        let repo = SDKInAppPurchaseSubmissions(client: stub)
        let result = try await repo.submitInAppPurchase(iapId: "iap-abc")

        #expect(result.id == "sub-1")
        #expect(result.iapId == "iap-abc")
    }

    @Test func `deleteSubmission performs void request via manual DELETE`() async throws {
        let stub = StubAPIClient()
        let repo = SDKInAppPurchaseSubmissions(client: stub)
        try await repo.deleteSubmission(submissionId: "sub-1")
        #expect(stub.voidRequestCalled == true)
    }
}
