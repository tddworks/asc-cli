import Mockable
import Testing
@testable import ASCCommand
@testable import ASCKit

@Suite
struct SubscriptionOfferCodeCustomCodesUpdateTests {

    @Test func `deactivates custom code and returns updated result`() async throws {
        let mockRepo = MockSubscriptionOfferCodes()
        given(mockRepo).updateCustomCode(customCodeId: .any, isActive: .any)
            .willReturn(SubscriptionOfferCodeCustomCode(
                id: "cc-1",
                offerCodeId: "oc-1",
                customCode: "SUMMER24",
                numberOfCodes: 500,
                isActive: false
            ))

        let cmd = try SubscriptionOfferCodeCustomCodesUpdate.parse(["--custom-code-id", "cc-1", "--active", "false", "--pretty"])
        let output = try await cmd.execute(repo: mockRepo)

        #expect(output.contains("cc-1"))
        #expect(output.contains("\"isActive\" : false"))
    }

    @Test func `throws for invalid active value`() async throws {
        let mockRepo = MockSubscriptionOfferCodes()
        let cmd = try SubscriptionOfferCodeCustomCodesUpdate.parse(["--custom-code-id", "cc-1", "--active", "maybe"])
        await #expect(throws: (any Error).self) {
            try await cmd.execute(repo: mockRepo)
        }
    }
}
