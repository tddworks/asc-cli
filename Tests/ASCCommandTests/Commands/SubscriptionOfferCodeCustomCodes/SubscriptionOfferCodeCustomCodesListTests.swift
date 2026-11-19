import Mockable
import Testing
@testable import ASCCommand
@testable import ASCKit

@Suite
struct SubscriptionOfferCodeCustomCodesListTests {

    @Test func `listed custom codes include customCode numberOfCodes and affordances`() async throws {
        let mockRepo = MockSubscriptionOfferCodes()
        given(mockRepo).listCustomCodes(offerCodeId: .any)
            .willReturn([
                SubscriptionOfferCodeCustomCode(
                    id: "cc-1",
                    offerCodeId: "oc-1",
                    customCode: "SUMMER24",
                    numberOfCodes: 500,
                    createdDate: "2024-06-01",
                    expirationDate: "2024-12-31",
                    isActive: true
                )
            ])

        let cmd = try SubscriptionOfferCodeCustomCodesList.parse(["--offer-code-id", "oc-1", "--pretty"])
        let output = try await cmd.execute(repo: mockRepo)

        #expect(output.contains("cc-1"))
        #expect(output.contains("SUMMER24"))
        #expect(output.contains("500"))
        #expect(output.contains("deactivate"))
    }

    @Test func `table output includes all row fields`() async throws {
        let mockRepo = MockSubscriptionOfferCodes()
        given(mockRepo).listCustomCodes(offerCodeId: .any)
            .willReturn([
                SubscriptionOfferCodeCustomCode(
                    id: "cc-1",
                    offerCodeId: "oc-1",
                    customCode: "SUMMER24",
                    numberOfCodes: 500,
                    expirationDate: "2024-12-31",
                    isActive: true
                )
            ])

        let cmd = try SubscriptionOfferCodeCustomCodesList.parse(["--offer-code-id", "oc-1", "--output", "table"])
        let output = try await cmd.execute(repo: mockRepo)

        #expect(output.contains("cc-1"))
        #expect(output.contains("SUMMER24"))
        #expect(output.contains("500"))
        #expect(output.contains("true"))
    }
}
