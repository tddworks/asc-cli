import Foundation
import Testing
@testable import Domain

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
}
