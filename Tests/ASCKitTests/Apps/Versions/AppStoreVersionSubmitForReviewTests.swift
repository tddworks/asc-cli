import Mockable
import Testing
@testable import ASCKit

@Suite
struct AppStoreVersionSubmitForReviewTests {
    private func version(_ state: AppStoreVersionState) -> AppStoreVersion {
        AppStoreVersion(id: "v-1", appId: "app-1", versionString: "1.0", platform: .iOS, state: state)
    }

    private let draft = ReviewSubmission(id: "sub-1", appId: "app-1", platform: .iOS, state: .readyForReview)
    private let submitted = ReviewSubmission(id: "sub-1", appId: "app-1", platform: .iOS, state: .waitingForReview)

    private func submissions(draftHolds items: [ReviewSubmissionItem]) -> MockSubmissionRepository {
        let submissions = MockSubmissionRepository()
        given(submissions).createSubmission(appId: .value("app-1"), platform: .value(.iOS)).willReturn(draft)
        given(submissions).listSubmissionItems(submissionId: .value("sub-1")).willReturn(items)
        given(submissions).addItem(submissionId: .value("sub-1"), target: .value(.appStoreVersion("v-1")))
            .willReturn(ReviewSubmissionItem(id: "item-new", submissionId: "sub-1", state: .readyForReview, linkedResourceId: "v-1"))
        given(submissions).submit(submissionId: .value("sub-1")).willReturn(submitted)
        return submissions
    }

    @Test func `should send an editable version to review in its app's open draft for its platform`() async throws {
        let submissions = submissions(draftHolds: [])

        let submission = try await version(.prepareForSubmission).submitForReview(to: submissions)

        #expect(submission == submitted)
        verify(submissions).addItem(submissionId: .value("sub-1"), target: .value(.appStoreVersion("v-1"))).called(1)
    }

    @Test func `should send a rejected version back to review`() async throws {
        let submission = try await version(.rejected).submitForReview(to: submissions(draftHolds: []))

        #expect(submission == submitted)
    }

    @Test func `should not add the version again when its draft already holds it`() async throws {
        let submissions = submissions(draftHolds: [
            ReviewSubmissionItem(id: "item-1", submissionId: "sub-1", state: .readyForReview, linkedResourceId: "v-1"),
        ])

        let submission = try await version(.prepareForSubmission).submitForReview(to: submissions)

        #expect(submission == submitted)
        verify(submissions).addItem(submissionId: .any, target: .any).called(0)
    }

    @Test func `should add the version when its draft holds only other items`() async throws {
        let submissions = submissions(draftHolds: [
            ReviewSubmissionItem(id: "item-1", submissionId: "sub-1", state: .readyForReview, linkedResourceId: "iap-v-1"),
        ])

        _ = try await version(.prepareForSubmission).submitForReview(to: submissions)

        verify(submissions).addItem(submissionId: .value("sub-1"), target: .value(.appStoreVersion("v-1"))).called(1)
    }

    @Test func `should refuse to send a version to review when it can no longer be edited`() async {
        let submissions = MockSubmissionRepository()

        await #expect(throws: ReviewSubmissionError.versionNotEditable(versionString: "1.0", state: .readyForSale)) {
            try await version(.readyForSale).submitForReview(to: submissions)
        }
        verify(submissions).createSubmission(appId: .any, platform: .any).called(0)
    }

    @Test func `should say why a version can't go to review and which ones can`() {
        let error = ReviewSubmissionError.versionNotEditable(versionString: "1.0", state: .readyForSale)

        #expect(error.description
            == "Version 1.0 can't go to review while it is Ready for Sale. Only a version being prepared for submission, or one that was rejected, can.")
    }
}
