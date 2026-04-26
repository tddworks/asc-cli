import Mockable
import Testing
@testable import ASCCommand
@testable import Domain

@Suite
struct SubscriptionsUnsubmitTests {

    @Test func `unsubmit deletes submission by id`() async throws {
        let mockRepo = MockSubscriptionSubmissionRepository()
        given(mockRepo).deleteSubmission(submissionId: .any).willReturn(())

        let cmd = try SubscriptionsUnsubmit.parse(["--submission-id", "sub-submit-1"])
        try await cmd.execute(repo: mockRepo)

        verify(mockRepo).deleteSubmission(submissionId: .value("sub-submit-1")).called(1)
    }
}
