import Mockable
import Testing
@testable import ASCCommand
@testable import ASCKit

@Suite
struct IAPOfferCodesListTests {

    @Test func `listed offer codes include name eligibilities active and affordances`() async throws {
        let mockRepo = MockInAppPurchaseOfferCodeRepository()
        given(mockRepo).listOfferCodes(iapId: .any)
            .willReturn([
                InAppPurchaseOfferCode(
                    id: "ioc-1",
                    iapId: "iap-1",
                    name: "BONUS2024",
                    customerEligibilities: [.nonSpender, .activeSpender],
                    isActive: true,
                    totalNumberOfCodes: 1000
                )
            ])

        let cmd = try IAPOfferCodesList.parse(["--iap-id", "iap-1", "--pretty"])
        let output = try await cmd.execute(repo: mockRepo)

        #expect(output.contains("ioc-1"))
        #expect(output.contains("BONUS2024"))
        #expect(output.contains("NON_SPENDER"))
        #expect(output.contains("ACTIVE_SPENDER"))
        #expect(output.contains("deactivate"))
    }

    @Test func `table output includes all row fields`() async throws {
        let mockRepo = MockInAppPurchaseOfferCodeRepository()
        given(mockRepo).listOfferCodes(iapId: .any)
            .willReturn([
                InAppPurchaseOfferCode(
                    id: "ioc-1",
                    iapId: "iap-1",
                    name: "BONUS2024",
                    customerEligibilities: [.churnedSpender],
                    isActive: true
                )
            ])

        let cmd = try IAPOfferCodesList.parse(["--iap-id", "iap-1", "--output", "table"])
        let output = try await cmd.execute(repo: mockRepo)

        #expect(output.contains("ioc-1"))
        #expect(output.contains("BONUS2024"))
        #expect(output.contains("true"))
    }
}
