import Mockable
import Testing
@testable import ASCCommand
@testable import Domain

@Suite
struct SubscriptionOfferCodeOneTimeCodesValuesTests {

    @Test func `returns CSV redemption values from repo`() async throws {
        let mockRepo = MockSubscriptionOfferCodeRepository()
        given(mockRepo).fetchOneTimeUseCodeValues(oneTimeCodeId: .any).willReturn("CODE1\nCODE2\n")

        let cmd = try SubscriptionOfferCodeOneTimeCodesValues.parse(["--one-time-code-id", "otc-1"])
        let output = try await cmd.execute(repo: mockRepo)

        #expect(output == "CODE1\nCODE2\n")
        verify(mockRepo).fetchOneTimeUseCodeValues(oneTimeCodeId: .value("otc-1")).called(1)
    }
}
