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

    // MARK: - Attachments

    @Test func `attachment carries parent messageId`() {
        let attachment = MockRepositoryFactory.makeResolutionCenterAttachment(id: "att-1", messageId: "msg-1")
        #expect(attachment.messageId == "msg-1")
    }

    @Test func `attachment with a downloadUrl is downloadable`() {
        let attachment = MockRepositoryFactory.makeResolutionCenterAttachment(
            downloadUrl: "https://iosapps-ssl.itunes.apple.com/file.png"
        )
        #expect(attachment.isDownloadable == true)
    }

    @Test func `attachment without a downloadUrl is not downloadable`() {
        let attachment = MockRepositoryFactory.makeResolutionCenterAttachment(downloadUrl: nil)
        #expect(attachment.isDownloadable == false)
    }

    @Test func `download urls are only valid for https on Apple or CDN hosts`() {
        #expect(ResolutionCenterAttachment.isValidDownloadURL("https://iosapps-ssl.itunes.apple.com/file.png") == true)
        #expect(ResolutionCenterAttachment.isValidDownloadURL("https://cdn.mzstatic.com/file.png") == true)
        #expect(ResolutionCenterAttachment.isValidDownloadURL("https://bucket.s3.amazonaws.com/file.png") == true)
        #expect(ResolutionCenterAttachment.isValidDownloadURL("https://d1.cloudfront.net/file.png") == true)
        #expect(ResolutionCenterAttachment.isValidDownloadURL("http://iosapps-ssl.itunes.apple.com/file.png") == false)
        #expect(ResolutionCenterAttachment.isValidDownloadURL("https://evil.example.com/file.png") == false)
        #expect(ResolutionCenterAttachment.isValidDownloadURL("https://notapple.com/file.png") == false)
    }

    @Test func `detail with a downloadable attachment exposes downloadAttachments affordance`() {
        let detail = MockRepositoryFactory.makeResolutionCenterDetail(
            id: "thread-1",
            submissionId: "sub-1",
            attachments: [MockRepositoryFactory.makeResolutionCenterAttachment()]
        )
        #expect(detail.affordances["downloadAttachments"] == "asc iris resolution-center get --out <dir> --submission-id sub-1")
    }

    @Test func `detail without attachments omits downloadAttachments affordance`() {
        let detail = MockRepositoryFactory.makeResolutionCenterDetail(attachments: [])
        #expect(detail.affordances["downloadAttachments"] == nil)
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
