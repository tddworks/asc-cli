import Testing
@testable import ASCKit

@Suite
struct ProductVersionTests {

    // MARK: - State

    @Test func `a version being prepared can be added to a review submission`() {
        let version = MockRepositoryFactory.makeProductVersion(state: .prepareForSubmission)
        #expect(version.isSubmittable)
        #expect(!version.isInReview)
    }

    @Test func `a rejected version can be added to a review submission again`() {
        #expect(MockRepositoryFactory.makeProductVersion(state: .rejected).isSubmittable)
        #expect(MockRepositoryFactory.makeProductVersion(state: .developerRejected).isSubmittable)
    }

    @Test func `a version waiting for or in review is in review and not submittable`() {
        for state in [ProductVersionState.waitingForReview, .inReview] {
            let version = MockRepositoryFactory.makeProductVersion(state: state)
            #expect(version.isInReview)
            #expect(!version.isSubmittable)
        }
    }

    @Test func `an accepted or approved version is approved`() {
        #expect(MockRepositoryFactory.makeProductVersion(state: .approved).isApproved)
        #expect(MockRepositoryFactory.makeProductVersion(state: .accepted).isApproved)
        #expect(!MockRepositoryFactory.makeProductVersion(state: .approved).isSubmittable)
    }

    @Test func `version states use Apple's raw values`() {
        #expect(ProductVersionState.prepareForSubmission.rawValue == "PREPARE_FOR_SUBMISSION")
        #expect(ProductVersionState.readyForReview.rawValue == "READY_FOR_REVIEW")
        #expect(ProductVersionState.replacedWithNewVersion.rawValue == "REPLACED_WITH_NEW_VERSION")
        #expect(ProductVersionKind.inAppPurchase.rawValue == "IN_APP_PURCHASE")
        #expect(ProductVersionKind.subscription.rawValue == "SUBSCRIPTION")
        #expect(ProductVersionKind.subscriptionGroup.rawValue == "SUBSCRIPTION_GROUP")
    }

    // MARK: - Affordances

    @Test func `each kind of version points at the command listing its product's versions`() {
        let iap = MockRepositoryFactory.makeProductVersion(productId: "iap-1", kind: .inAppPurchase)
        let sub = MockRepositoryFactory.makeProductVersion(productId: "sub-1", kind: .subscription)
        let group = MockRepositoryFactory.makeProductVersion(productId: "grp-1", kind: .subscriptionGroup)
        #expect(iap.affordances["listVersions"] == "asc iap versions list --iap-id iap-1")
        #expect(sub.affordances["listVersions"] == "asc subscriptions versions list --subscription-id sub-1")
        #expect(group.affordances["listVersions"] == "asc subscription-groups versions list --group-id grp-1")
    }

    @Test func `a submittable version offers adding itself to a review submission`() {
        let iap = MockRepositoryFactory.makeProductVersion(id: "iv-1", kind: .inAppPurchase)
        let sub = MockRepositoryFactory.makeProductVersion(id: "sv-1", kind: .subscription)
        let group = MockRepositoryFactory.makeProductVersion(id: "gv-1", kind: .subscriptionGroup)
        #expect(iap.affordances["addToSubmission"]
            == "asc review-submissions items add --iap-version-id iv-1 --submission-id <submission-id>")
        #expect(sub.affordances["addToSubmission"]
            == "asc review-submissions items add --submission-id <submission-id> --subscription-version-id sv-1")
        #expect(group.affordances["addToSubmission"]
            == "asc review-submissions items add --submission-id <submission-id> --subscription-group-version-id gv-1")
    }

    @Test func `a version already in review does not offer adding it to a submission`() {
        let version = MockRepositoryFactory.makeProductVersion(state: .waitingForReview)
        #expect(version.affordances["addToSubmission"] == nil)
    }

    @Test func `version REST links list siblings and add to a submission`() {
        let version = MockRepositoryFactory.makeProductVersion(id: "sv-1", productId: "sub-1", kind: .subscription)
        #expect(version.apiLinks["listVersions"]?.href == "/api/v1/subscriptions/sub-1/versions")
        #expect(version.apiLinks["listVersions"]?.method == "GET")
        #expect(version.apiLinks["addToSubmission"]?.href == "/api/v1/review-submissions/<submission-id>/items")
        #expect(version.apiLinks["addToSubmission"]?.method == "POST")
    }
}
