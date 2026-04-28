import Mockable
import Testing
@testable import ASCCommand
@testable import Domain

@Suite
struct IAPOfferCodeOneTimeCodesCreateTests {

    @Test func `creates IAP one-time codes and returns result with affordances`() async throws {
        let mockRepo = MockInAppPurchaseOfferCodeRepository()
        given(mockRepo).createOneTimeUseCode(
            offerCodeId: .any, numberOfCodes: .any, expirationDate: .any, environment: .any
        ).willReturn(InAppPurchaseOfferCodeOneTimeUseCode(
            id: "iotc-new",
            offerCodeId: "ioc-1",
            numberOfCodes: 400,
            createdDate: "2024-09-01",
            expirationDate: "2025-03-01",
            isActive: true
        ))

        let cmd = try IAPOfferCodeOneTimeCodesCreate.parse([
            "--offer-code-id", "ioc-1",
            "--number-of-codes", "400",
            "--expiration-date", "2025-03-01",
            "--pretty",
        ])
        let output = try await cmd.execute(repo: mockRepo)

        #expect(output.contains("iotc-new"))
        #expect(output.contains("400"))
    }

    @Test func `defaults environment to production when flag omitted`() async throws {
        let mockRepo = MockInAppPurchaseOfferCodeRepository()
        given(mockRepo).createOneTimeUseCode(
            offerCodeId: .any, numberOfCodes: .any, expirationDate: .any, environment: .any
        ).willReturn(InAppPurchaseOfferCodeOneTimeUseCode(
            id: "iotc-default",
            offerCodeId: "ioc-1",
            numberOfCodes: 400,
            expirationDate: "2025-03-01",
            isActive: true,
            environment: .production
        ))

        let cmd = try IAPOfferCodeOneTimeCodesCreate.parse([
            "--offer-code-id", "ioc-1",
            "--number-of-codes", "400",
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
        let mockRepo = MockInAppPurchaseOfferCodeRepository()
        given(mockRepo).createOneTimeUseCode(
            offerCodeId: .any, numberOfCodes: .any, expirationDate: .any, environment: .any
        ).willReturn(InAppPurchaseOfferCodeOneTimeUseCode(
            id: "iotc-sb",
            offerCodeId: "ioc-1",
            numberOfCodes: 10,
            expirationDate: "2025-03-01",
            isActive: true,
            environment: .sandbox
        ))

        let cmd = try IAPOfferCodeOneTimeCodesCreate.parse([
            "--offer-code-id", "ioc-1",
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
