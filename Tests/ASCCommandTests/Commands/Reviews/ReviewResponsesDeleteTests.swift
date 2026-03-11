import Mockable
import Testing
@testable import ASCCommand
@testable import Domain

@Suite
struct ReviewResponsesDeleteTests {

    @Test func `delete response calls repository`() async throws {
        let mockRepo = MockCustomerReviewRepository()
        given(mockRepo).deleteResponse(responseId: .any).willReturn(())

        let cmd = try ReviewResponsesDelete.parse(["--response-id", "resp-1"])
        try await cmd.execute(repo: mockRepo)

        verify(mockRepo).deleteResponse(responseId: .value("resp-1")).called(.once)
    }
}
