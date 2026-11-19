import Mockable
import Testing
@testable import ASCCommand
@testable import ASCKit

@Suite
struct SubscriptionOfferCodeOneTimeCodesListTests {

    @Test func `listed one-time codes include numberOfCodes active and affordances`() async throws {
        let mockRepo = MockSubscriptionOfferCodes()
        given(mockRepo).listOneTimeUseCodes(offerCodeId: .any)
            .willReturn([
                SubscriptionOfferCodeOneTimeUseCode(
                    id: "otc-1",
                    offerCodeId: "oc-1",
                    numberOfCodes: 200,
                    createdDate: "2024-06-01",
                    expirationDate: "2024-12-31",
                    isActive: true
                )
            ])

        let cmd = try SubscriptionOfferCodeOneTimeCodesList.parse(["--offer-code-id", "oc-1", "--pretty"])
        let output = try await cmd.execute(repo: mockRepo)

        #expect(output.contains("otc-1"))
        #expect(output.contains("200"))
        #expect(output.contains("deactivate"))
    }

    @Test func `table output includes all row fields`() async throws {
        let mockRepo = MockSubscriptionOfferCodes()
        given(mockRepo).listOneTimeUseCodes(offerCodeId: .any)
            .willReturn([
                SubscriptionOfferCodeOneTimeUseCode(
                    id: "otc-1",
                    offerCodeId: "oc-1",
                    numberOfCodes: 200,
                    expirationDate: "2024-12-31",
                    isActive: true
                )
            ])

        let cmd = try SubscriptionOfferCodeOneTimeCodesList.parse(["--offer-code-id", "oc-1", "--output", "table"])
        let output = try await cmd.execute(repo: mockRepo)

        #expect(output.contains("otc-1"))
        #expect(output.contains("200"))
        #expect(output.contains("true"))
    }
}
