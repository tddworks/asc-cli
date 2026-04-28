@preconcurrency import AppStoreConnect_Swift_SDK
import Testing
@testable import Infrastructure
@testable import Domain

@Suite
struct SDKInAppPurchaseOfferCodeRepositoryTests {

    // MARK: - listOfferCodes

    @Test func `listOfferCodes injects iapId into each offer code`() async throws {
        let stub = StubAPIClient()
        stub.willReturn(InAppPurchaseOfferCodesResponse(
            data: [
                AppStoreConnect_Swift_SDK.InAppPurchaseOfferCode(
                    type: .inAppPurchaseOfferCodes,
                    id: "iap-oc-1",
                    attributes: .init(
                        name: "BONUS",
                        customerEligibilities: [.nonSpender],
                        isActive: true
                    )
                ),
                AppStoreConnect_Swift_SDK.InAppPurchaseOfferCode(
                    type: .inAppPurchaseOfferCodes,
                    id: "iap-oc-2",
                    attributes: .init(
                        name: "REWARD",
                        customerEligibilities: [.activeSpender, .churnedSpender],
                        isActive: false
                    )
                ),
            ],
            links: .init(this: "")
        ))

        let repo = SDKInAppPurchaseOfferCodeRepository(client: stub)
        let result = try await repo.listOfferCodes(iapId: "iap-99")

        #expect(result.count == 2)
        #expect(result.allSatisfy { $0.iapId == "iap-99" })
    }

    @Test func `listOfferCodes maps attributes from SDK types`() async throws {
        let stub = StubAPIClient()
        stub.willReturn(InAppPurchaseOfferCodesResponse(
            data: [
                AppStoreConnect_Swift_SDK.InAppPurchaseOfferCode(
                    type: .inAppPurchaseOfferCodes,
                    id: "iap-oc-1",
                    attributes: .init(
                        name: "PROMO",
                        customerEligibilities: [.nonSpender, .activeSpender],
                        isActive: true
                    )
                ),
            ],
            links: .init(this: "")
        ))

        let repo = SDKInAppPurchaseOfferCodeRepository(client: stub)
        let result = try await repo.listOfferCodes(iapId: "iap-1")

        #expect(result[0].id == "iap-oc-1")
        #expect(result[0].name == "PROMO")
        #expect(result[0].customerEligibilities == [.nonSpender, .activeSpender])
        #expect(result[0].isActive == true)
    }

    @Test func `listOfferCodes maps production and sandbox code counts`() async throws {
        let stub = StubAPIClient()
        stub.willReturn(InAppPurchaseOfferCodesResponse(
            data: [
                AppStoreConnect_Swift_SDK.InAppPurchaseOfferCode(
                    type: .inAppPurchaseOfferCodes,
                    id: "iap-oc-1",
                    attributes: .init(
                        name: "PROMO",
                        customerEligibilities: [.nonSpender],
                        productionCodeCount: 8_500,
                        sandboxCodeCount: 120,
                        isActive: true
                    )
                ),
            ],
            links: .init(this: "")
        ))

        let repo = SDKInAppPurchaseOfferCodeRepository(client: stub)
        let result = try await repo.listOfferCodes(iapId: "iap-1")

        #expect(result[0].productionCodeCount == 8_500)
        #expect(result[0].sandboxCodeCount == 120)
    }

    // MARK: - createOfferCode

    @Test func `createOfferCode injects iapId into result`() async throws {
        let stub = StubAPIClient()
        stub.willReturn(InAppPurchaseOfferCodeResponse(
            data: AppStoreConnect_Swift_SDK.InAppPurchaseOfferCode(
                type: .inAppPurchaseOfferCodes,
                id: "iap-oc-new",
                attributes: .init(
                    name: "LAUNCH",
                    customerEligibilities: [.nonSpender],
                    isActive: true
                )
            ),
            links: .init(this: "")
        ))

        let repo = SDKInAppPurchaseOfferCodeRepository(client: stub)
        let result = try await repo.createOfferCode(
            iapId: "iap-42",
            name: "LAUNCH",
            customerEligibilities: [.nonSpender],
            prices: [
                OfferCodePriceInput(territory: "USA", pricePointId: "pp-1"),
                OfferCodePriceInput(territory: "BRA", pricePointId: nil),
            ]
        )

        #expect(result.id == "iap-oc-new")
        #expect(result.iapId == "iap-42")
        #expect(result.name == "LAUNCH")
    }

    // MARK: - updateOfferCode

    @Test func `updateOfferCode maps response and injects empty iapId`() async throws {
        let stub = StubAPIClient()
        stub.willReturn(InAppPurchaseOfferCodeResponse(
            data: AppStoreConnect_Swift_SDK.InAppPurchaseOfferCode(
                type: .inAppPurchaseOfferCodes,
                id: "iap-oc-1",
                attributes: .init(
                    name: "BONUS",
                    customerEligibilities: [.nonSpender],
                    isActive: false
                )
            ),
            links: .init(this: "")
        ))

        let repo = SDKInAppPurchaseOfferCodeRepository(client: stub)
        let result = try await repo.updateOfferCode(offerCodeId: "iap-oc-1", isActive: false)

        #expect(result.id == "iap-oc-1")
        #expect(result.isActive == false)
        #expect(result.iapId == "")
    }

    // MARK: - listCustomCodes

    @Test func `listCustomCodes injects offerCodeId`() async throws {
        let stub = StubAPIClient()
        stub.willReturn(InAppPurchaseOfferCodeCustomCodesResponse(
            data: [
                AppStoreConnect_Swift_SDK.InAppPurchaseOfferCodeCustomCode(
                    type: .inAppPurchaseOfferCodeCustomCodes,
                    id: "iap-cc-1",
                    attributes: .init(
                        customCode: "SAVE10",
                        numberOfCodes: 200,
                        expirationDate: "2025-12-31",
                        isActive: true
                    )
                ),
            ],
            links: .init(this: "")
        ))

        let repo = SDKInAppPurchaseOfferCodeRepository(client: stub)
        let result = try await repo.listCustomCodes(offerCodeId: "iap-oc-10")

        #expect(result.count == 1)
        #expect(result[0].offerCodeId == "iap-oc-10")
        #expect(result[0].customCode == "SAVE10")
        #expect(result[0].numberOfCodes == 200)
        #expect(result[0].isActive == true)
    }

    // MARK: - createCustomCode

    @Test func `createCustomCode injects offerCodeId into result`() async throws {
        let stub = StubAPIClient()
        stub.willReturn(InAppPurchaseOfferCodeCustomCodeResponse(
            data: AppStoreConnect_Swift_SDK.InAppPurchaseOfferCodeCustomCode(
                type: .inAppPurchaseOfferCodeCustomCodes,
                id: "iap-cc-new",
                attributes: .init(
                    customCode: "WELCOME",
                    numberOfCodes: 300,
                    expirationDate: "2025-06-30",
                    isActive: true
                )
            ),
            links: .init(this: "")
        ))

        let repo = SDKInAppPurchaseOfferCodeRepository(client: stub)
        let result = try await repo.createCustomCode(
            offerCodeId: "iap-oc-5",
            customCode: "WELCOME",
            numberOfCodes: 300,
            expirationDate: "2025-06-30"
        )

        #expect(result.id == "iap-cc-new")
        #expect(result.offerCodeId == "iap-oc-5")
        #expect(result.customCode == "WELCOME")
    }

    // MARK: - updateCustomCode

    @Test func `updateCustomCode maps response and injects empty offerCodeId`() async throws {
        let stub = StubAPIClient()
        stub.willReturn(InAppPurchaseOfferCodeCustomCodeResponse(
            data: AppStoreConnect_Swift_SDK.InAppPurchaseOfferCodeCustomCode(
                type: .inAppPurchaseOfferCodeCustomCodes,
                id: "iap-cc-1",
                attributes: .init(
                    customCode: "SAVE10",
                    numberOfCodes: 200,
                    isActive: false
                )
            ),
            links: .init(this: "")
        ))

        let repo = SDKInAppPurchaseOfferCodeRepository(client: stub)
        let result = try await repo.updateCustomCode(customCodeId: "iap-cc-1", isActive: false)

        #expect(result.id == "iap-cc-1")
        #expect(result.isActive == false)
        #expect(result.offerCodeId == "")
    }

    // MARK: - listOneTimeUseCodes

    @Test func `listOneTimeUseCodes injects offerCodeId`() async throws {
        let stub = StubAPIClient()
        stub.willReturn(InAppPurchaseOfferCodeOneTimeUseCodesResponse(
            data: [
                AppStoreConnect_Swift_SDK.InAppPurchaseOfferCodeOneTimeUseCode(
                    type: .inAppPurchaseOfferCodeOneTimeUseCodes,
                    id: "iap-otc-1",
                    attributes: .init(
                        numberOfCodes: 2000,
                        expirationDate: "2025-12-31",
                        isActive: true
                    )
                ),
            ],
            links: .init(this: "")
        ))

        let repo = SDKInAppPurchaseOfferCodeRepository(client: stub)
        let result = try await repo.listOneTimeUseCodes(offerCodeId: "iap-oc-20")

        #expect(result.count == 1)
        #expect(result[0].offerCodeId == "iap-oc-20")
        #expect(result[0].numberOfCodes == 2000)
        #expect(result[0].isActive == true)
    }

    // MARK: - createOneTimeUseCode

    @Test func `createOneTimeUseCode injects offerCodeId into result`() async throws {
        let stub = StubAPIClient()
        stub.willReturn(InAppPurchaseOfferCodeOneTimeUseCodeResponse(
            data: AppStoreConnect_Swift_SDK.InAppPurchaseOfferCodeOneTimeUseCode(
                type: .inAppPurchaseOfferCodeOneTimeUseCodes,
                id: "iap-otc-new",
                attributes: .init(
                    numberOfCodes: 750,
                    expirationDate: "2026-01-01",
                    isActive: true
                )
            ),
            links: .init(this: "")
        ))

        let repo = SDKInAppPurchaseOfferCodeRepository(client: stub)
        let result = try await repo.createOneTimeUseCode(
            offerCodeId: "iap-oc-7",
            numberOfCodes: 750,
            expirationDate: "2026-01-01",
            environment: .production
        )

        #expect(result.id == "iap-otc-new")
        #expect(result.offerCodeId == "iap-oc-7")
        #expect(result.numberOfCodes == 750)
    }

    @Test func `createOneTimeUseCode maps environment from SDK response`() async throws {
        let stub = StubAPIClient()
        stub.willReturn(InAppPurchaseOfferCodeOneTimeUseCodeResponse(
            data: AppStoreConnect_Swift_SDK.InAppPurchaseOfferCodeOneTimeUseCode(
                type: .inAppPurchaseOfferCodeOneTimeUseCodes,
                id: "iap-otc-sb",
                attributes: .init(
                    numberOfCodes: 10,
                    expirationDate: "2026-01-01",
                    isActive: true,
                    environment: .sandbox
                )
            ),
            links: .init(this: "")
        ))

        let repo = SDKInAppPurchaseOfferCodeRepository(client: stub)
        let result = try await repo.createOneTimeUseCode(
            offerCodeId: "iap-oc-7",
            numberOfCodes: 10,
            expirationDate: "2026-01-01",
            environment: .sandbox
        )

        #expect(result.environment == .sandbox)
    }

    // MARK: - updateOneTimeUseCode

    @Test func `updateOneTimeUseCode maps response and injects empty offerCodeId`() async throws {
        let stub = StubAPIClient()
        stub.willReturn(InAppPurchaseOfferCodeOneTimeUseCodeResponse(
            data: AppStoreConnect_Swift_SDK.InAppPurchaseOfferCodeOneTimeUseCode(
                type: .inAppPurchaseOfferCodeOneTimeUseCodes,
                id: "iap-otc-1",
                attributes: .init(
                    numberOfCodes: 2000,
                    isActive: false
                )
            ),
            links: .init(this: "")
        ))

        let repo = SDKInAppPurchaseOfferCodeRepository(client: stub)
        let result = try await repo.updateOneTimeUseCode(oneTimeCodeId: "iap-otc-1", isActive: false)

        #expect(result.id == "iap-otc-1")
        #expect(result.isActive == false)
        #expect(result.offerCodeId == "")
    }

    @Test func `listPrices injects offerCodeId and maps territory + pricePoint`() async throws {
        let stub = StubAPIClient()
        stub.willReturn(InAppPurchaseOfferPricesResponse(
            data: [
                AppStoreConnect_Swift_SDK.InAppPurchaseOfferPrice(
                    type: .inAppPurchaseOfferPrices, id: "p-1",
                    relationships: .init(
                        territory: .init(data: .init(type: .territories, id: "USA")),
                        pricePoint: .init(data: .init(type: .inAppPurchasePricePoints, id: "pp-9"))
                    )
                ),
            ],
            links: .init(this: "")
        ))

        let repo = SDKInAppPurchaseOfferCodeRepository(client: stub)
        let result = try await repo.listPrices(offerCodeId: "oc-77")

        #expect(result[0].offerCodeId == "oc-77")
        #expect(result[0].territory == "USA")
        #expect(result[0].pricePointId == "pp-9")
    }

    @Test func `fetchOneTimeUseCodeValues returns CSV string from SDK`() async throws {
        let stub = StubAPIClient()
        stub.willReturn("CODE1\nCODE2\nCODE3\n")
        let repo = SDKInAppPurchaseOfferCodeRepository(client: stub)
        let result = try await repo.fetchOneTimeUseCodeValues(oneTimeCodeId: "otc-1")
        #expect(result == "CODE1\nCODE2\nCODE3\n")
    }
}
