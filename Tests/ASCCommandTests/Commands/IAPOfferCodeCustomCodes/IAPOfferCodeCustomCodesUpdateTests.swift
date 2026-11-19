import Mockable
import Testing
@testable import ASCCommand
@testable import ASCKit

@Suite
struct IAPOfferCodeCustomCodesUpdateTests {

    @Test func `deactivates IAP custom code and returns updated result`() async throws {
        let mockRepo = MockInAppPurchaseOfferCodes()
        given(mockRepo).updateCustomCode(customCodeId: .any, isActive: .any)
            .willReturn(InAppPurchaseOfferCodeCustomCode(
                id: "icc-1",
                offerCodeId: "ioc-1",
                customCode: "IAPBONUS",
                numberOfCodes: 300,
                isActive: false
            ))

        let cmd = try IAPOfferCodeCustomCodesUpdate.parse(["--custom-code-id", "icc-1", "--active", "false", "--pretty"])
        let output = try await cmd.execute(repo: mockRepo)

        #expect(output.contains("icc-1"))
        #expect(output.contains("\"isActive\" : false"))
    }

    @Test func `throws for invalid active value`() async throws {
        let mockRepo = MockInAppPurchaseOfferCodes()
        let cmd = try IAPOfferCodeCustomCodesUpdate.parse(["--custom-code-id", "icc-1", "--active", "maybe"])
        await #expect(throws: (any Error).self) {
            try await cmd.execute(repo: mockRepo)
        }
    }
}
