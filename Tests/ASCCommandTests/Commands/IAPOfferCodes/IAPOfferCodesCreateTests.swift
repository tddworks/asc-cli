import Mockable
import Testing
@testable import ASCCommand
@testable import Domain

@Suite
struct IAPOfferCodesCreateTests {

    @Test func `creates IAP offer code and returns it with affordances`() async throws {
        let mockRepo = MockInAppPurchaseOfferCodeRepository()
        given(mockRepo).createOfferCode(
            iapId: .any, name: .any, customerEligibilities: .any, prices: .any
        ).willReturn(InAppPurchaseOfferCode(
            id: "ioc-new",
            iapId: "iap-1",
            name: "BONUS2024",
            customerEligibilities: [.nonSpender, .activeSpender],
            isActive: true
        ))

        let cmd = try IAPOfferCodesCreate.parse([
            "--iap-id", "iap-1",
            "--name", "BONUS2024",
            "--eligibility", "NON_SPENDER",
            "--eligibility", "ACTIVE_SPENDER",
            "--pretty",
        ])
        let output = try await cmd.execute(repo: mockRepo)

        #expect(output.contains("ioc-new"))
        #expect(output.contains("BONUS2024"))
    }

    @Test func `throws for invalid eligibility`() async throws {
        let mockRepo = MockInAppPurchaseOfferCodeRepository()
        let cmd = try IAPOfferCodesCreate.parse([
            "--iap-id", "iap-1",
            "--name", "TEST",
            "--eligibility", "INVALID",
        ])
        await #expect(throws: (any Error).self) {
            try await cmd.execute(repo: mockRepo)
        }
    }

    @Test func `forwards paid and free per-territory prices to repository`() async throws {
        let mockRepo = MockInAppPurchaseOfferCodeRepository()
        given(mockRepo).createOfferCode(
            iapId: .any, name: .any, customerEligibilities: .any, prices: .any
        ).willReturn(InAppPurchaseOfferCode(
            id: "ioc-new", iapId: "iap-1", name: "BONUS",
            customerEligibilities: [.nonSpender], isActive: true
        ))

        let cmd = try IAPOfferCodesCreate.parse([
            "--iap-id", "iap-1",
            "--name", "BONUS",
            "--eligibility", "NON_SPENDER",
            "--price", "USA=pp-usa",
            "--price", "JPN=pp-jpn",
            "--free-territory", "BRA",
        ])
        _ = try await cmd.execute(repo: mockRepo)

        verify(mockRepo).createOfferCode(
            iapId: .any, name: .any, customerEligibilities: .any,
            prices: .value([
                OfferCodePriceInput(territory: "USA", pricePointId: "pp-usa"),
                OfferCodePriceInput(territory: "JPN", pricePointId: "pp-jpn"),
                OfferCodePriceInput(territory: "BRA", pricePointId: nil),
            ])
        ).called(1)
    }

    @Test func `defaults to empty prices array when no flags provided`() async throws {
        let mockRepo = MockInAppPurchaseOfferCodeRepository()
        given(mockRepo).createOfferCode(
            iapId: .any, name: .any, customerEligibilities: .any, prices: .any
        ).willReturn(InAppPurchaseOfferCode(
            id: "ioc-new", iapId: "iap-1", name: "BONUS",
            customerEligibilities: [.nonSpender], isActive: true
        ))

        let cmd = try IAPOfferCodesCreate.parse([
            "--iap-id", "iap-1",
            "--name", "BONUS",
            "--eligibility", "NON_SPENDER",
        ])
        _ = try await cmd.execute(repo: mockRepo)

        verify(mockRepo).createOfferCode(
            iapId: .any, name: .any, customerEligibilities: .any,
            prices: .value([])
        ).called(1)
    }

    @Test func `rejects malformed --price flag`() async throws {
        let mockRepo = MockInAppPurchaseOfferCodeRepository()
        let cmd = try IAPOfferCodesCreate.parse([
            "--iap-id", "iap-1",
            "--name", "TEST",
            "--eligibility", "NON_SPENDER",
            "--price", "missing-equals-sign",
        ])
        await #expect(throws: (any Error).self) {
            try await cmd.execute(repo: mockRepo)
        }
    }
}
