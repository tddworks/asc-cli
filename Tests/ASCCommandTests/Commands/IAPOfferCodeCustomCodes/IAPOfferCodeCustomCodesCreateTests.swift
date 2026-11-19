import Mockable
import Testing
@testable import ASCCommand
@testable import ASCKit

@Suite
struct IAPOfferCodeCustomCodesCreateTests {

    @Test func `creates IAP custom code and returns result with affordances`() async throws {
        let mockRepo = MockInAppPurchaseOfferCodeRepository()
        given(mockRepo).createCustomCode(
            offerCodeId: .any, customCode: .any,
            numberOfCodes: .any, expirationDate: .any
        ).willReturn(InAppPurchaseOfferCodeCustomCode(
            id: "icc-new",
            offerCodeId: "ioc-1",
            customCode: "IAPFALL",
            numberOfCodes: 750,
            createdDate: "2024-09-01",
            expirationDate: "2025-03-01",
            isActive: true
        ))

        let cmd = try IAPOfferCodeCustomCodesCreate.parse([
            "--offer-code-id", "ioc-1",
            "--custom-code", "IAPFALL",
            "--number-of-codes", "750",
            "--expiration-date", "2025-03-01",
            "--pretty",
        ])
        let output = try await cmd.execute(repo: mockRepo)

        #expect(output.contains("icc-new"))
        #expect(output.contains("IAPFALL"))
        #expect(output.contains("750"))
    }
}
