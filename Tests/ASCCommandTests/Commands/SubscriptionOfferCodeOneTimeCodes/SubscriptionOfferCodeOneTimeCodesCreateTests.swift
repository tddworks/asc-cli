import Mockable
import Testing
@testable import ASCCommand
@testable import Domain

@Suite
struct SubscriptionOfferCodeOneTimeCodesCreateTests {

    @Test func `creates one-time codes and returns result with affordances`() async throws {
        let mockRepo = MockSubscriptionOfferCodeRepository()
        given(mockRepo).createOneTimeUseCode(
            offerCodeId: .any, numberOfCodes: .any, expirationDate: .any, environment: .any
        ).willReturn(SubscriptionOfferCodeOneTimeUseCode(
            id: "otc-new",
            offerCodeId: "oc-1",
            numberOfCodes: 500,
            createdDate: "2024-09-01",
            expirationDate: "2025-03-01",
            isActive: true
        ))

        let cmd = try SubscriptionOfferCodeOneTimeCodesCreate.parse([
            "--offer-code-id", "oc-1",
            "--number-of-codes", "500",
            "--expiration-date", "2025-03-01",
            "--pretty",
        ])
        let output = try await cmd.execute(repo: mockRepo)

        #expect(output.contains("otc-new"))
        #expect(output.contains("500"))
    }

    @Test func `defaults environment to production when flag omitted`() async throws {
        let mockRepo = MockSubscriptionOfferCodeRepository()
        given(mockRepo).createOneTimeUseCode(
            offerCodeId: .any, numberOfCodes: .any, expirationDate: .any, environment: .any
        ).willReturn(SubscriptionOfferCodeOneTimeUseCode(
            id: "otc-default",
            offerCodeId: "oc-1",
            numberOfCodes: 500,
            expirationDate: "2025-03-01",
            isActive: true,
            environment: .production
        ))

        let cmd = try SubscriptionOfferCodeOneTimeCodesCreate.parse([
            "--offer-code-id", "oc-1",
            "--number-of-codes", "500",
            "--expiration-date", "2025-03-01",
            "--pretty",
        ])
        _ = try await cmd.execute(repo: mockRepo)

        verify(mockRepo).createOneTimeUseCode(
            offerCodeId: .any, numberOfCodes: .any, expirationDate: .any,
            environment: .value(.production)
        ).called(1)
    }

    @Test func `forwards sandbox environment to repository`() async throws {
        let mockRepo = MockSubscriptionOfferCodeRepository()
        given(mockRepo).createOneTimeUseCode(
            offerCodeId: .any, numberOfCodes: .any, expirationDate: .any, environment: .any
        ).willReturn(SubscriptionOfferCodeOneTimeUseCode(
            id: "otc-sb",
            offerCodeId: "oc-1",
            numberOfCodes: 10,
            expirationDate: "2025-03-01",
            isActive: true,
            environment: .sandbox
        ))

        let cmd = try SubscriptionOfferCodeOneTimeCodesCreate.parse([
            "--offer-code-id", "oc-1",
            "--number-of-codes", "10",
            "--expiration-date", "2025-03-01",
            "--environment", "sandbox",
            "--pretty",
        ])
        let output = try await cmd.execute(repo: mockRepo)

        verify(mockRepo).createOneTimeUseCode(
            offerCodeId: .any, numberOfCodes: .any, expirationDate: .any,
            environment: .value(.sandbox)
        ).called(1)
        #expect(output.contains("SANDBOX"))
    }
}
