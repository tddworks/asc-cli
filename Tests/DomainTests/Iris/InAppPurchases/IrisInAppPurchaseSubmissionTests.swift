import Testing
@testable import Domain

@Suite
struct IrisInAppPurchaseSubmissionTests {

    @Test func `submission carries id, iap, and submitWithNextAppStoreVersion`() {
        let submission = MockRepositoryFactory.makeIrisInAppPurchaseSubmission(
            id: "sub-42", iapId: "iap-7", submitWithNextAppStoreVersion: true
        )
        #expect(submission.id == "sub-42")
        #expect(submission.iapId == "iap-7")
        #expect(submission.submitWithNextAppStoreVersion == true)
    }

    @Test func `submission affordance points back at the parent IAP`() {
        let submission = MockRepositoryFactory.makeIrisInAppPurchaseSubmission(iapId: "iap-7")
        #expect(submission.affordances["viewIAP"] == "asc iap get --iap-id iap-7")
    }

    @Test func `submission apiLinks viewIAP resolves to public IAP REST path`() {
        let submission = MockRepositoryFactory.makeIrisInAppPurchaseSubmission(iapId: "iap-7")
        #expect(submission.apiLinks["viewIAP"]?.href == "/api/v1/iap/iap-7")
        #expect(submission.apiLinks["viewIAP"]?.method == "GET")
    }
}
