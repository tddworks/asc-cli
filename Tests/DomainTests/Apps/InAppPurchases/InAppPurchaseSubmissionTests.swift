import Testing
@testable import Domain

@Suite
struct InAppPurchaseSubmissionTests {

    @Test func `submission carries iapId`() {
        let submission = MockRepositoryFactory.makeInAppPurchaseSubmission(id: "sub-1", iapId: "iap-abc")
        #expect(submission.iapId == "iap-abc")
        #expect(submission.id == "sub-1")
    }

    @Test func `submission affordances include listLocalizations`() {
        let submission = MockRepositoryFactory.makeInAppPurchaseSubmission(id: "sub-1", iapId: "iap-abc")
        #expect(submission.affordances["listLocalizations"] == "asc iap-localizations list --iap-id iap-abc")
    }

    @Test func `submission affordances include unsubmit with submission id`() {
        let submission = MockRepositoryFactory.makeInAppPurchaseSubmission(id: "sub-1", iapId: "iap-abc")
        #expect(submission.affordances["unsubmit"] == "asc iap unsubmit --submission-id sub-1")
    }
}
