import Mockable
import Testing
@testable import ASCCommand
@testable import ASCKit

@Suite
struct IAPOfferCodeOneTimeCodesUpdateTests {

    @Test func `deactivates IAP one-time code and returns updated result`() async throws {
        let mockRepo = MockInAppPurchaseOfferCodes()
        given(mockRepo).updateOneTimeUseCode(oneTimeCodeId: .any, isActive: .any)
            .willReturn(InAppPurchaseOfferCodeOneTimeUseCode(
                id: "iotc-1",
                offerCodeId: "ioc-1",
                numberOfCodes: 150,
                isActive: false
            ))

        let cmd = try IAPOfferCodeOneTimeCodesUpdate.parse(["--one-time-code-id", "iotc-1", "--active", "false", "--pretty"])
        let output = try await cmd.execute(repo: mockRepo)

        #expect(output.contains("iotc-1"))
        #expect(output.contains("\"isActive\" : false"))
    }

    @Test func `throws for invalid active value`() async throws {
        let mockRepo = MockInAppPurchaseOfferCodes()
        let cmd = try IAPOfferCodeOneTimeCodesUpdate.parse(["--one-time-code-id", "iotc-1", "--active", "maybe"])
        await #expect(throws: (any Error).self) {
            try await cmd.execute(repo: mockRepo)
        }
    }
}
