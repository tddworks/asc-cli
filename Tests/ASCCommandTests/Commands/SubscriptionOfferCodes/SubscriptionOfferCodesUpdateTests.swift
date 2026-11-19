import Mockable
import Testing
@testable import ASCCommand
@testable import ASCKit

@Suite
struct SubscriptionOfferCodesUpdateTests {

    @Test func `deactivates offer code and returns updated result`() async throws {
        let mockRepo = MockSubscriptionOfferCodeRepository()
        given(mockRepo).updateOfferCode(offerCodeId: .any, isActive: .any)
            .willReturn(SubscriptionOfferCode(
                id: "oc-1",
                subscriptionId: "sub-1",
                name: "SUMMER2024",
                customerEligibilities: [.new],
                offerEligibility: .stackable,
                duration: .oneMonth,
                offerMode: .freeTrial,
                numberOfPeriods: 1,
                isActive: false
            ))

        let cmd = try SubscriptionOfferCodesUpdate.parse(["--offer-code-id", "oc-1", "--active", "false", "--pretty"])
        let output = try await cmd.execute(repo: mockRepo)

        #expect(output.contains("oc-1"))
        #expect(output.contains("\"isActive\" : false"))
    }

    @Test func `throws for invalid active value`() async throws {
        let mockRepo = MockSubscriptionOfferCodeRepository()
        let cmd = try SubscriptionOfferCodesUpdate.parse(["--offer-code-id", "oc-1", "--active", "maybe"])
        await #expect(throws: (any Error).self) {
            try await cmd.execute(repo: mockRepo)
        }
    }
}
