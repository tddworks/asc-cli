import Mockable
import Testing
@testable import ASCCommand
@testable import ASCKit

@Suite
struct IAPOfferCodeOneTimeCodesListTests {

    @Test func `listed one-time codes include numberOfCodes active and affordances`() async throws {
        let mockRepo = MockInAppPurchaseOfferCodeRepository()
        given(mockRepo).listOneTimeUseCodes(offerCodeId: .any)
            .willReturn([
                InAppPurchaseOfferCodeOneTimeUseCode(
                    id: "iotc-1",
                    offerCodeId: "ioc-1",
                    numberOfCodes: 150,
                    createdDate: "2024-06-01",
                    expirationDate: "2024-12-31",
                    isActive: true
                )
            ])

        let cmd = try IAPOfferCodeOneTimeCodesList.parse(["--offer-code-id", "ioc-1", "--pretty"])
        let output = try await cmd.execute(repo: mockRepo)

        #expect(output.contains("iotc-1"))
        #expect(output.contains("150"))
        #expect(output.contains("deactivate"))
    }

    @Test func `table output includes all row fields`() async throws {
        let mockRepo = MockInAppPurchaseOfferCodeRepository()
        given(mockRepo).listOneTimeUseCodes(offerCodeId: .any)
            .willReturn([
                InAppPurchaseOfferCodeOneTimeUseCode(
                    id: "iotc-1",
                    offerCodeId: "ioc-1",
                    numberOfCodes: 150,
                    expirationDate: "2024-12-31",
                    isActive: true
                )
            ])

        let cmd = try IAPOfferCodeOneTimeCodesList.parse(["--offer-code-id", "ioc-1", "--output", "table"])
        let output = try await cmd.execute(repo: mockRepo)

        #expect(output.contains("iotc-1"))
        #expect(output.contains("150"))
        #expect(output.contains("true"))
    }
}
