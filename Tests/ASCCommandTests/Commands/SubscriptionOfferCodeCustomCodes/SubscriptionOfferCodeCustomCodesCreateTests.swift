import Mockable
import Testing
@testable import ASCCommand
@testable import ASCKit

@Suite
struct SubscriptionOfferCodeCustomCodesCreateTests {

    @Test func `creates custom code and returns it with affordances`() async throws {
        let mockRepo = MockSubscriptionOfferCodeRepository()
        given(mockRepo).createCustomCode(
            offerCodeId: .any, customCode: .any,
            numberOfCodes: .any, expirationDate: .any
        ).willReturn(SubscriptionOfferCodeCustomCode(
            id: "cc-new",
            offerCodeId: "oc-1",
            customCode: "FALL2024",
            numberOfCodes: 1000,
            createdDate: "2024-09-01",
            expirationDate: "2025-03-01",
            isActive: true
        ))

        let cmd = try SubscriptionOfferCodeCustomCodesCreate.parse([
            "--offer-code-id", "oc-1",
            "--custom-code", "FALL2024",
            "--number-of-codes", "1000",
            "--expiration-date", "2025-03-01",
            "--pretty",
        ])
        let output = try await cmd.execute(repo: mockRepo)

        #expect(output.contains("cc-new"))
        #expect(output.contains("FALL2024"))
        #expect(output.contains("1000"))
    }
}
