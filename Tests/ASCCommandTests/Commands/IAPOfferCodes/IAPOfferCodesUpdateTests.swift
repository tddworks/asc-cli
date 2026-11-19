import Mockable
import Testing
@testable import ASCCommand
@testable import ASCKit

@Suite
struct IAPOfferCodesUpdateTests {

    @Test func `deactivates IAP offer code and returns updated result`() async throws {
        let mockRepo = MockInAppPurchaseOfferCodeRepository()
        given(mockRepo).updateOfferCode(offerCodeId: .any, isActive: .any)
            .willReturn(InAppPurchaseOfferCode(
                id: "ioc-1",
                iapId: "iap-1",
                name: "BONUS2024",
                customerEligibilities: [.nonSpender],
                isActive: false
            ))

        let cmd = try IAPOfferCodesUpdate.parse(["--offer-code-id", "ioc-1", "--active", "false", "--pretty"])
        let output = try await cmd.execute(repo: mockRepo)

        #expect(output.contains("ioc-1"))
        #expect(output.contains("\"isActive\" : false"))
    }

    @Test func `throws for invalid active value`() async throws {
        let mockRepo = MockInAppPurchaseOfferCodeRepository()
        let cmd = try IAPOfferCodesUpdate.parse(["--offer-code-id", "ioc-1", "--active", "maybe"])
        await #expect(throws: (any Error).self) {
            try await cmd.execute(repo: mockRepo)
        }
    }
}
