import Foundation
import Testing
@testable import Domain

@Suite
struct ReviewSubmissionItemTests {

    // MARK: - Parent ID injection

    @Test func `item carries parent submissionId`() {
        let item = MockRepositoryFactory.makeReviewSubmissionItem(id: "i-1", submissionId: "sub-1")
        #expect(item.submissionId == "sub-1")
    }

    // MARK: - State semantics (rejection-focused)

    @Test func `rejected item flags isRejected`() {
        let item = MockRepositoryFactory.makeReviewSubmissionItem(state: .rejected)
        #expect(item.isRejected == true)
        #expect(item.isApproved == false)
        #expect(item.isPending == false)
    }

    @Test func `approved item flags isApproved`() {
        let item = MockRepositoryFactory.makeReviewSubmissionItem(state: .approved)
        #expect(item.isApproved == true)
        #expect(item.isRejected == false)
    }

    @Test func `accepted item flags isApproved`() {
        // ACCEPTED is Apple's interim "passed initial intake" — agents treat it like
        // approved (no action needed) until a terminal state arrives.
        let item = MockRepositoryFactory.makeReviewSubmissionItem(state: .accepted)
        #expect(item.isApproved == true)
        #expect(item.isRejected == false)
    }

    @Test func `readyForReview item is pending`() {
        let item = MockRepositoryFactory.makeReviewSubmissionItem(state: .readyForReview)
        #expect(item.isPending == true)
        #expect(item.isRejected == false)
        #expect(item.isApproved == false)
    }

    @Test func `removed item is neither rejected nor approved`() {
        let item = MockRepositoryFactory.makeReviewSubmissionItem(state: .removed)
        #expect(item.isRejected == false)
        #expect(item.isApproved == false)
        #expect(item.isPending == false)
    }

    // MARK: - Affordances

    @Test func `item affordances include getSubmission to walk back to parent`() {
        let item = MockRepositoryFactory.makeReviewSubmissionItem(id: "i-1", submissionId: "sub-1")
        #expect(item.affordances["getSubmission"] == "asc review-submissions get --submission-id sub-1")
    }

    @Test func `item with linked appStoreVersion exposes getVersion affordance`() {
        let item = MockRepositoryFactory.makeReviewSubmissionItem(
            id: "i-1",
            submissionId: "sub-1",
            linkedResourceId: "v-9",
            linkedResourceType: .appStoreVersion
        )
        #expect(item.affordances["getVersion"] == "asc versions get --version-id v-9")
    }

    @Test func `rejected item affordances include getResolutionDetails iris command`() {
        let item = MockRepositoryFactory.makeReviewSubmissionItem(
            id: "i-1",
            submissionId: "sub-1",
            state: .rejected
        )
        #expect(item.affordances["getResolutionDetails"] == "asc iris resolution-center get --submission-id sub-1")
    }

    @Test func `pending item omits getResolutionDetails affordance`() {
        let item = MockRepositoryFactory.makeReviewSubmissionItem(
            id: "i-1",
            submissionId: "sub-1",
            state: .readyForReview
        )
        #expect(item.affordances["getResolutionDetails"] == nil)
    }

    @Test func `item without linked resource omits getVersion affordance`() {
        let item = MockRepositoryFactory.makeReviewSubmissionItem(
            id: "i-1",
            submissionId: "sub-1",
            linkedResourceId: nil,
            linkedResourceType: nil
        )
        #expect(item.affordances["getVersion"] == nil)
    }
}
