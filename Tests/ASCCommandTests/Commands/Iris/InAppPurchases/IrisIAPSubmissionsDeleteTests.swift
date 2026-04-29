import Mockable
import Testing
@testable import ASCCommand
@testable import Domain

@Suite
struct IrisIAPSubmissionsDeleteTests {

    @Test func `delete invokes iris repo with submission id`() async throws {
        let mockCookieProvider = MockIrisCookieProvider()
        given(mockCookieProvider).resolveSession().willReturn(
            IrisSession(cookies: "myacinfo=test")
        )

        let mockRepo = MockIrisInAppPurchaseSubmissionRepository()
        given(mockRepo).deleteSubmission(session: .any, submissionId: .any).willReturn(())

        let cmd = try IrisIAPSubmissionsDelete.parse(["--submission-id", "iap-7"])
        try await cmd.execute(cookieProvider: mockCookieProvider, repo: mockRepo)

        verify(mockRepo).deleteSubmission(
            session: .any, submissionId: .value("iap-7")
        ).called(1)
    }
}
