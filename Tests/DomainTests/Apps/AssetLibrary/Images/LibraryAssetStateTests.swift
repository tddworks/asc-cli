import Testing
@testable import Domain

@Suite
struct LibraryAssetStateTests {

    @Test func `should use App Store Connect's own state names`() {
        #expect(LibraryAssetState.allCases.map(\.rawValue) == [
            "AWAITING_UPLOAD", "UPLOAD_COMPLETE", "FAILED", "COMPLETE", "PREPARE_FOR_SUBMISSION",
            "READY_FOR_REVIEW", "WAITING_FOR_REVIEW", "IN_REVIEW", "ACCEPTED", "APPROVED",
            "REJECTED", "ARCHIVED",
        ])
    }

    @Test func `should be awaiting upload only until the file has been sent`() {
        #expect(LibraryAssetState.allCases.filter(\.isAwaitingUpload) == [.awaitingUpload])
    }

    @Test func `should be processing once the upload is complete`() {
        #expect(LibraryAssetState.allCases.filter(\.isProcessing) == [.uploadComplete])
    }

    @Test func `should be placeable once processed and all the way through review`() {
        #expect(LibraryAssetState.allCases.filter(\.isPlaceable) == [
            .complete, .prepareForSubmission, .readyForReview, .waitingForReview, .inReview, .accepted, .approved,
        ])
    }

    @Test func `should be in review while waiting for or in App Review`() {
        #expect(LibraryAssetState.allCases.filter(\.isInReview) == [.waitingForReview, .inReview])
    }

    @Test func `should be approved when App Review accepted or approved it`() {
        #expect(LibraryAssetState.allCases.filter(\.isApproved) == [.accepted, .approved])
    }

    @Test func `should be archivable only once approved`() {
        #expect(LibraryAssetState.allCases.filter(\.isArchivable) == [.approved])
    }

    @Test func `should have failed when processing failed or App Review rejected it`() {
        #expect(LibraryAssetState.allCases.filter(\.isFailed) == [.failed, .rejected])
    }
}
