import Mockable
import Testing
@testable import ASCCommand
@testable import Domain

@Suite
struct IAPOfferCodeOneTimeCodesValuesTests {

    @Test func `returns CSV redemption values from repo`() async throws {
        let mockRepo = MockInAppPurchaseOfferCodeRepository()
        given(mockRepo).fetchOneTimeUseCodeValues(oneTimeCodeId: .any).willReturn("CODE1\nCODE2\nCODE3\n")

        let cmd = try IAPOfferCodeOneTimeCodesValues.parse(["--one-time-code-id", "otc-1"])
        let output = try await cmd.execute(repo: mockRepo)

        #expect(output == "CODE1\nCODE2\nCODE3\n")
        verify(mockRepo).fetchOneTimeUseCodeValues(oneTimeCodeId: .value("otc-1")).called(1)
    }
}
