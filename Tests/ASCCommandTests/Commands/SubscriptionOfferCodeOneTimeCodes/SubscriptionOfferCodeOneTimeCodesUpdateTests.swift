import Mockable
import Testing
@testable import ASCCommand
@testable import ASCKit

@Suite
struct SubscriptionOfferCodeOneTimeCodesUpdateTests {

    @Test func `deactivates one-time code and returns updated result`() async throws {
        let mockRepo = MockSubscriptionOfferCodes()
        given(mockRepo).updateOneTimeUseCode(oneTimeCodeId: .any, isActive: .any)
            .willReturn(SubscriptionOfferCodeOneTimeUseCode(
                id: "otc-1",
                offerCodeId: "oc-1",
                numberOfCodes: 200,
                isActive: false
            ))

        let cmd = try SubscriptionOfferCodeOneTimeCodesUpdate.parse(["--one-time-code-id", "otc-1", "--active", "false", "--pretty"])
        let output = try await cmd.execute(repo: mockRepo)

        #expect(output.contains("otc-1"))
        #expect(output.contains("\"isActive\" : false"))
    }

    @Test func `throws for invalid active value`() async throws {
        let mockRepo = MockSubscriptionOfferCodes()
        let cmd = try SubscriptionOfferCodeOneTimeCodesUpdate.parse(["--one-time-code-id", "otc-1", "--active", "maybe"])
        await #expect(throws: (any Error).self) {
            try await cmd.execute(repo: mockRepo)
        }
    }
}
