import Mockable
import Testing
@testable import ASCCommand
@testable import ASCKit

@Suite
struct IAPOfferCodeCustomCodesListTests {

    @Test func `listed custom codes include customCode numberOfCodes and affordances`() async throws {
        let mockRepo = MockInAppPurchaseOfferCodes()
        given(mockRepo).listCustomCodes(offerCodeId: .any)
            .willReturn([
                InAppPurchaseOfferCodeCustomCode(
                    id: "icc-1",
                    offerCodeId: "ioc-1",
                    customCode: "IAPBONUS",
                    numberOfCodes: 300,
                    createdDate: "2024-06-01",
                    expirationDate: "2024-12-31",
                    isActive: true
                )
            ])

        let cmd = try IAPOfferCodeCustomCodesList.parse(["--offer-code-id", "ioc-1", "--pretty"])
        let output = try await cmd.execute(repo: mockRepo)

        #expect(output.contains("icc-1"))
        #expect(output.contains("IAPBONUS"))
        #expect(output.contains("300"))
        #expect(output.contains("deactivate"))
    }

    @Test func `table output includes all row fields`() async throws {
        let mockRepo = MockInAppPurchaseOfferCodes()
        given(mockRepo).listCustomCodes(offerCodeId: .any)
            .willReturn([
                InAppPurchaseOfferCodeCustomCode(
                    id: "icc-1",
                    offerCodeId: "ioc-1",
                    customCode: "IAPBONUS",
                    numberOfCodes: 300,
                    expirationDate: "2024-12-31",
                    isActive: true
                )
            ])

        let cmd = try IAPOfferCodeCustomCodesList.parse(["--offer-code-id", "ioc-1", "--output", "table"])
        let output = try await cmd.execute(repo: mockRepo)

        #expect(output.contains("icc-1"))
        #expect(output.contains("IAPBONUS"))
        #expect(output.contains("300"))
        #expect(output.contains("true"))
    }
}
