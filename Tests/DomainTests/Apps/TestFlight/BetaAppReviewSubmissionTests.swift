import Foundation
import Testing
@testable import Domain

@Suite
struct BetaAppReviewSubmissionTests {

    // MARK: - Parent ID

    @Test func `submission carries buildId`() {
        let submission = MockRepositoryFactory.makeBetaAppReviewSubmission(id: "sub-1", buildId: "build-42")
        #expect(submission.buildId == "build-42")
    }

    // MARK: - State Semantics

    @Test func `submission is pending when waiting for review`() {
        let submission = MockRepositoryFactory.makeBetaAppReviewSubmission(state: .waitingForReview)
        #expect(submission.isPending == true)
        #expect(submission.isApproved == false)
        #expect(submission.isRejected == false)
        #expect(submission.isInReview == false)
    }

    @Test func `submission is in review`() {
        let submission = MockRepositoryFactory.makeBetaAppReviewSubmission(state: .inReview)
        #expect(submission.isInReview == true)
        #expect(submission.isPending == false)
    }

    @Test func `submission is approved`() {
        let submission = MockRepositoryFactory.makeBetaAppReviewSubmission(state: .approved)
        #expect(submission.isApproved == true)
        #expect(submission.isPending == false)
    }

    @Test func `submission is rejected`() {
        let submission = MockRepositoryFactory.makeBetaAppReviewSubmission(state: .rejected)
        #expect(submission.isRejected == true)
        #expect(submission.isApproved == false)
    }

    // MARK: - State Raw Values

    @Test func `state raw values match API format`() {
        #expect(BetaReviewState.waitingForReview.rawValue == "WAITING_FOR_REVIEW")
        #expect(BetaReviewState.inReview.rawValue == "IN_REVIEW")
        #expect(BetaReviewState.rejected.rawValue == "REJECTED")
        #expect(BetaReviewState.approved.rawValue == "APPROVED")
    }

    // MARK: - Affordances

    @Test func `submission affordances include getSubmission`() {
        let submission = MockRepositoryFactory.makeBetaAppReviewSubmission(id: "sub-1")
        #expect(submission.affordances["getSubmission"] == "asc beta-review submissions get --submission-id sub-1")
    }

    @Test func `submission affordances include listSubmissions via buildId`() {
        let submission = MockRepositoryFactory.makeBetaAppReviewSubmission(id: "sub-1", buildId: "build-1")
        #expect(submission.affordances["listSubmissions"] == "asc beta-review submissions list --build-id build-1")
    }

    // MARK: - Codable

    @Test func `submission encodes state as raw value`() throws {
        let submission = MockRepositoryFactory.makeBetaAppReviewSubmission(id: "sub-1", buildId: "build-1", state: .approved)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        let data = try encoder.encode(submission)
        let json = String(data: data, encoding: .utf8)!
        #expect(json.contains("\"APPROVED\""))
    }

    @Test func `submission omits nil submittedDate from JSON`() throws {
        let submission = MockRepositoryFactory.makeBetaAppReviewSubmission(submittedDate: nil)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        let data = try encoder.encode(submission)
        let json = String(data: data, encoding: .utf8)!
        #expect(!json.contains("submittedDate"))
    }
}
