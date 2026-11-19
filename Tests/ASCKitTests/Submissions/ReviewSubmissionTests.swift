import Foundation
import Testing
@testable import ASCKit

@Suite
struct ReviewSubmissionTests {

    @Test func `submission carries parent appId`() {
        let submission = MockRepositoryFactory.makeReviewSubmission(id: "sub-1", appId: "app-1")
        #expect(submission.appId == "app-1")
    }

    @Test func `waitingForReview submission is pending`() {
        let submission = MockRepositoryFactory.makeReviewSubmission(state: .waitingForReview)
        #expect(submission.isPending == true)
        #expect(submission.isComplete == false)
        #expect(submission.hasIssues == false)
    }

    @Test func `inReview submission is pending`() {
        let submission = MockRepositoryFactory.makeReviewSubmission(state: .inReview)
        #expect(submission.isPending == true)
    }

    @Test func `complete submission is complete`() {
        let submission = MockRepositoryFactory.makeReviewSubmission(state: .complete)
        #expect(submission.isComplete == true)
        #expect(submission.isPending == false)
        #expect(submission.hasIssues == false)
    }

    @Test func `unresolvedIssues submission has issues`() {
        let submission = MockRepositoryFactory.makeReviewSubmission(state: .unresolvedIssues)
        #expect(submission.hasIssues == true)
        #expect(submission.isPending == false)
        #expect(submission.isComplete == false)
    }

    @Test func `canceling submission is pending`() {
        let submission = MockRepositoryFactory.makeReviewSubmission(state: .canceling)
        #expect(submission.isPending == true)
    }

    @Test func `completing submission is pending`() {
        let submission = MockRepositoryFactory.makeReviewSubmission(state: .completing)
        #expect(submission.isPending == true)
    }

    @Test func `readyForReview submission is not pending and not complete`() {
        let submission = MockRepositoryFactory.makeReviewSubmission(state: .readyForReview)
        #expect(submission.isPending == false)
        #expect(submission.isComplete == false)
        #expect(submission.hasIssues == false)
    }

    // MARK: - Resolution Center affordance

    @Test func `unresolvedIssues submission affordances include getResolutionDetails iris command`() {
        let submission = MockRepositoryFactory.makeReviewSubmission(id: "sub-1", state: .unresolvedIssues)
        #expect(submission.affordances["getResolutionDetails"] == "asc iris resolution-center get --submission-id sub-1")
    }

    @Test func `waitingForReview submission omits getResolutionDetails affordance`() {
        let submission = MockRepositoryFactory.makeReviewSubmission(id: "sub-1", state: .waitingForReview)
        #expect(submission.affordances["getResolutionDetails"] == nil)
    }

    @Test(arguments: zip(
        ReviewSubmissionState.allCases,
        [
            "Ready for Review",
            "Waiting for Review",
            "In Review",
            "Unresolved Issues",
            "Canceling",
            "Completing",
            "Complete",
        ]
    ))
    func `state displayName is human readable`(state: ReviewSubmissionState, expected: String) {
        #expect(state.displayName == expected)
    }

    // MARK: - Draft submissions

    @Test func `a draft or rejected submission can still take items and be submitted`() {
        #expect(MockRepositoryFactory.makeReviewSubmission(state: .readyForReview).isEditable)
        #expect(MockRepositoryFactory.makeReviewSubmission(state: .unresolvedIssues).isEditable)
        for state in [ReviewSubmissionState.waitingForReview, .inReview, .canceling, .completing, .complete] {
            #expect(!MockRepositoryFactory.makeReviewSubmission(state: state).isEditable)
        }
    }

    @Test func `a draft submission offers adding an item and submitting it`() {
        let submission = MockRepositoryFactory.makeReviewSubmission(id: "sub-1", state: .readyForReview)
        #expect(submission.affordances["addItem"]
            == "asc review-submissions items add --submission-id sub-1 --version-id <version-id>")
        #expect(submission.affordances["submit"] == "asc review-submissions submit --submission-id sub-1")
        #expect(submission.apiLinks["addItem"]?.href == "/api/v1/review-submissions/sub-1/items")
        #expect(submission.apiLinks["addItem"]?.method == "POST")
        #expect(submission.apiLinks["submit"]?.href == "/api/v1/review-submissions/sub-1/submit")
        #expect(submission.apiLinks["submit"]?.method == "POST")
    }

    @Test func `a submission already sent to review offers neither adding items nor submitting`() {
        let submission = MockRepositoryFactory.makeReviewSubmission(state: .waitingForReview)
        #expect(submission.affordances["addItem"] == nil)
        #expect(submission.affordances["submit"] == nil)
    }
}
