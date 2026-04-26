import Mockable
import Testing
@testable import ASCCommand
@testable import Domain

@Suite
struct IAPUnsubmitTests {

    @Test func `unsubmit deletes submission by id`() async throws {
        let mockRepo = MockInAppPurchaseSubmissionRepository()
        given(mockRepo).deleteSubmission(submissionId: .any).willReturn(())

        let cmd = try IAPUnsubmit.parse(["--submission-id", "sub-1"])
        try await cmd.execute(repo: mockRepo)

        verify(mockRepo).deleteSubmission(submissionId: .value("sub-1")).called(1)
    }
}
