import Testing
@testable import Domain

@Suite
struct SubscriptionSubmissionTests {

    @Test func `submission carries subscriptionId`() {
        let sub = MockRepositoryFactory.makeSubscriptionSubmission(id: "s-1", subscriptionId: "sub-42")
        #expect(sub.subscriptionId == "sub-42")
    }

    @Test func `affordances include listLocalizations`() {
        let sub = MockRepositoryFactory.makeSubscriptionSubmission(subscriptionId: "sub-42")
        #expect(sub.affordances["listLocalizations"] == "asc subscription-localizations list --subscription-id sub-42")
    }

    @Test func `submission affordances include unsubmit with submission id`() {
        let sub = MockRepositoryFactory.makeSubscriptionSubmission(id: "s-1", subscriptionId: "sub-42")
        #expect(sub.affordances["unsubmit"] == "asc subscriptions unsubmit --submission-id s-1")
    }

    @Test func `submit affordance present only when readyToSubmit`() {
        let ready = MockRepositoryFactory.makeSubscription(state: .readyToSubmit)
        let other = MockRepositoryFactory.makeSubscription(state: .missingMetadata)

        #expect(ready.affordances["submit"] == "asc subscriptions submit --subscription-id sub-1")
        #expect(other.affordances["submit"] == nil)
    }
}
