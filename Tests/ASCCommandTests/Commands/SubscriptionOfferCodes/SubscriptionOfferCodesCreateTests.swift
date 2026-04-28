import Mockable
import Testing
@testable import ASCCommand
@testable import Domain

@Suite
struct SubscriptionOfferCodesCreateTests {

    @Test func `creates offer code and returns it with affordances`() async throws {
        let mockRepo = MockSubscriptionOfferCodeRepository()
        given(mockRepo).createOfferCode(
            subscriptionId: .any, name: .any, customerEligibilities: .any,
            offerEligibility: .any, duration: .any, offerMode: .any,
            numberOfPeriods: .any, isAutoRenewEnabled: .any, prices: .any
        ).willReturn(SubscriptionOfferCode(
            id: "oc-new",
            subscriptionId: "sub-1",
            name: "SUMMER2024",
            customerEligibilities: [.new, .lapsed],
            offerEligibility: .stackable,
            duration: .oneMonth,
            offerMode: .freeTrial,
            numberOfPeriods: 1,
            isActive: true
        ))

        let cmd = try SubscriptionOfferCodesCreate.parse([
            "--subscription-id", "sub-1",
            "--name", "SUMMER2024",
            "--duration", "ONE_MONTH",
            "--mode", "FREE_TRIAL",
            "--periods", "1",
            "--eligibility", "NEW",
            "--eligibility", "LAPSED",
            "--offer-eligibility", "STACKABLE",
            "--pretty",
        ])
        let output = try await cmd.execute(repo: mockRepo)

        #expect(output.contains("oc-new"))
        #expect(output.contains("SUMMER2024"))
        #expect(output.contains("ONE_MONTH"))
        #expect(output.contains("FREE_TRIAL"))
    }

    @Test func `forwards paid prices and isAutoRenewEnabled true by default`() async throws {
        let mockRepo = MockSubscriptionOfferCodeRepository()
        given(mockRepo).createOfferCode(
            subscriptionId: .any, name: .any, customerEligibilities: .any,
            offerEligibility: .any, duration: .any, offerMode: .any,
            numberOfPeriods: .any, isAutoRenewEnabled: .any, prices: .any
        ).willReturn(SubscriptionOfferCode(
            id: "oc-new", subscriptionId: "sub-1", name: "PROMO",
            customerEligibilities: [.new], offerEligibility: .stackable,
            duration: .oneMonth, offerMode: .freeTrial, numberOfPeriods: 1, isActive: true
        ))

        let cmd = try SubscriptionOfferCodesCreate.parse([
            "--subscription-id", "sub-1",
            "--name", "PROMO",
            "--duration", "ONE_MONTH",
            "--mode", "FREE_TRIAL",
            "--periods", "1",
            "--eligibility", "NEW",
            "--offer-eligibility", "STACKABLE",
            "--price", "USA=spp-usa",
            "--free-territory", "BRA",
        ])
        _ = try await cmd.execute(repo: mockRepo)

        verify(mockRepo).createOfferCode(
            subscriptionId: .any, name: .any, customerEligibilities: .any,
            offerEligibility: .any, duration: .any, offerMode: .any,
            numberOfPeriods: .any,
            isAutoRenewEnabled: .value(true),
            prices: .value([
                OfferCodePriceInput(territory: "USA", pricePointId: "spp-usa"),
                OfferCodePriceInput(territory: "BRA", pricePointId: nil),
            ])
        ).called(1)
    }

    @Test func `forwards isAutoRenewEnabled false when flag set`() async throws {
        let mockRepo = MockSubscriptionOfferCodeRepository()
        given(mockRepo).createOfferCode(
            subscriptionId: .any, name: .any, customerEligibilities: .any,
            offerEligibility: .any, duration: .any, offerMode: .any,
            numberOfPeriods: .any, isAutoRenewEnabled: .any, prices: .any
        ).willReturn(SubscriptionOfferCode(
            id: "oc-new", subscriptionId: "sub-1", name: "ONE_TIME",
            customerEligibilities: [.new], offerEligibility: .stackable,
            duration: .oneMonth, offerMode: .freeTrial, numberOfPeriods: 1, isActive: true
        ))

        let cmd = try SubscriptionOfferCodesCreate.parse([
            "--subscription-id", "sub-1",
            "--name", "ONE_TIME",
            "--duration", "ONE_MONTH",
            "--mode", "FREE_TRIAL",
            "--periods", "1",
            "--eligibility", "NEW",
            "--offer-eligibility", "STACKABLE",
            "--auto-renew", "false",
        ])
        _ = try await cmd.execute(repo: mockRepo)

        verify(mockRepo).createOfferCode(
            subscriptionId: .any, name: .any, customerEligibilities: .any,
            offerEligibility: .any, duration: .any, offerMode: .any,
            numberOfPeriods: .any,
            isAutoRenewEnabled: .value(false),
            prices: .any
        ).called(1)
    }

    @Test func `throws for invalid duration`() async throws {
        let mockRepo = MockSubscriptionOfferCodeRepository()
        let cmd = try SubscriptionOfferCodesCreate.parse([
            "--subscription-id", "sub-1",
            "--name", "TEST",
            "--duration", "DAILY",
            "--mode", "FREE_TRIAL",
            "--periods", "1",
            "--eligibility", "NEW",
            "--offer-eligibility", "STACKABLE",
        ])
        await #expect(throws: (any Error).self) {
            try await cmd.execute(repo: mockRepo)
        }
    }

    @Test func `throws for invalid mode`() async throws {
        let mockRepo = MockSubscriptionOfferCodeRepository()
        let cmd = try SubscriptionOfferCodesCreate.parse([
            "--subscription-id", "sub-1",
            "--name", "TEST",
            "--duration", "ONE_MONTH",
            "--mode", "UNKNOWN_MODE",
            "--periods", "1",
            "--eligibility", "NEW",
            "--offer-eligibility", "STACKABLE",
        ])
        await #expect(throws: (any Error).self) {
            try await cmd.execute(repo: mockRepo)
        }
    }

    @Test func `throws for invalid eligibility`() async throws {
        let mockRepo = MockSubscriptionOfferCodeRepository()
        let cmd = try SubscriptionOfferCodesCreate.parse([
            "--subscription-id", "sub-1",
            "--name", "TEST",
            "--duration", "ONE_MONTH",
            "--mode", "FREE_TRIAL",
            "--periods", "1",
            "--eligibility", "INVALID",
            "--offer-eligibility", "STACKABLE",
        ])
        await #expect(throws: (any Error).self) {
            try await cmd.execute(repo: mockRepo)
        }
    }

    @Test func `throws for invalid offer eligibility`() async throws {
        let mockRepo = MockSubscriptionOfferCodeRepository()
        let cmd = try SubscriptionOfferCodesCreate.parse([
            "--subscription-id", "sub-1",
            "--name", "TEST",
            "--duration", "ONE_MONTH",
            "--mode", "FREE_TRIAL",
            "--periods", "1",
            "--eligibility", "NEW",
            "--offer-eligibility", "INVALID",
        ])
        await #expect(throws: (any Error).self) {
            try await cmd.execute(repo: mockRepo)
        }
    }
}
