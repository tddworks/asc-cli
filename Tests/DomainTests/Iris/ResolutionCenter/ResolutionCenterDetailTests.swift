import Foundation
import Testing
@testable import Domain

@Suite
struct ResolutionCenterDetailTests {

    // MARK: - Parent ID injection

    @Test func `detail carries parent submissionId`() {
        let detail = MockRepositoryFactory.makeResolutionCenterDetail(id: "thread-1", submissionId: "sub-1")
        #expect(detail.submissionId == "sub-1")
    }

    @Test func `message carries parent threadId`() {
        let message = MockRepositoryFactory.makeResolutionCenterMessage(id: "msg-1", threadId: "thread-1")
        #expect(message.threadId == "thread-1")
    }

    // MARK: - Semantics

    @Test func `detail with rejection reasons flags hasRejections`() {
        let detail = MockRepositoryFactory.makeResolutionCenterDetail(
            rejectionReasons: [MockRepositoryFactory.makeReviewRejectionReason(code: "2.1")]
        )
        #expect(detail.hasRejections == true)
    }

    @Test func `detail without rejection reasons does not flag hasRejections`() {
        let detail = MockRepositoryFactory.makeResolutionCenterDetail(rejectionReasons: [])
        #expect(detail.hasRejections == false)
    }

    // MARK: - Plain text conversion

    @Test func `plainText copy strips html tags and unescapes entities in message bodies`() {
        let detail = MockRepositoryFactory.makeResolutionCenterDetail(
            messages: [
                MockRepositoryFactory.makeResolutionCenterMessage(
                    body: "<p>Guideline 2.1 &amp; 2.3<br/>We were unable to review.</p>"
                ),
            ]
        )
        let plain = detail.plainText()
        #expect(plain.messages[0].body == "Guideline 2.1 & 2.3\nWe were unable to review.")
    }

    // MARK: - Affordances (CLI surface)

    @Test func `detail affordances back-link to submission and rejected items`() {
        let detail = MockRepositoryFactory.makeResolutionCenterDetail(id: "thread-1", submissionId: "sub-1")
        #expect(detail.affordances["getSubmission"] == "asc review-submissions get --submission-id sub-1")
        #expect(detail.affordances["listRejectedItems"] == "asc review-submissions items list --state REJECTED --submission-id sub-1")
    }

    // MARK: - REST surface (_links derive from the same structuredAffordances)

    @Test func `detail apiLinks resolve getSubmission REST path`() {
        let detail = MockRepositoryFactory.makeResolutionCenterDetail(id: "thread-1", submissionId: "sub-1")
        #expect(detail.apiLinks["getSubmission"]?.href == "/api/v1/review-submissions/sub-1")
        #expect(detail.apiLinks["getSubmission"]?.method == "GET")
    }

    @Test func `submission apiLinks resolve resolution-center under iris review-submissions`() {
        let submission = MockRepositoryFactory.makeReviewSubmission(id: "sub-1", state: .unresolvedIssues)
        #expect(submission.apiLinks["getResolutionDetails"]?.href == "/api/v1/iris/review-submissions/sub-1/resolution-center")
        #expect(submission.apiLinks["getResolutionDetails"]?.method == "GET")
    }
}
