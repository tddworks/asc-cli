@preconcurrency import AppStoreConnect_Swift_SDK
import Testing
@testable import Infrastructure
@testable import Domain

@Suite
struct SDKSubscriptionOfferCodeRepositoryTests {

    // MARK: - listOfferCodes

    @Test func `listOfferCodes injects subscriptionId into each offer code`() async throws {
        let stub = StubAPIClient()
        stub.willReturn(SubscriptionOfferCodesResponse(
            data: [
                AppStoreConnect_Swift_SDK.SubscriptionOfferCode(
                    type: .subscriptionOfferCodes,
                    id: "oc-1",
                    attributes: .init(
                        name: "SUMMER",
                        customerEligibilities: [.new],
                        offerEligibility: .stackWithIntroOffers,
                        duration: .oneMonth,
                        offerMode: .freeTrial,
                        numberOfPeriods: 1,
                        totalNumberOfCodes: 100,
                        isActive: true
                    )
                ),
                AppStoreConnect_Swift_SDK.SubscriptionOfferCode(
                    type: .subscriptionOfferCodes,
                    id: "oc-2",
                    attributes: .init(
                        name: "WINTER",
                        customerEligibilities: [.expired],
                        offerEligibility: .replaceIntroOffers,
                        duration: .threeMonths,
                        offerMode: .payAsYouGo,
                        numberOfPeriods: 3,
                        isActive: false
                    )
                ),
            ],
            links: .init(this: "")
        ))

        let repo = SDKSubscriptionOfferCodeRepository(client: stub)
        let result = try await repo.listOfferCodes(subscriptionId: "sub-99")

        #expect(result.count == 2)
        #expect(result.allSatisfy { $0.subscriptionId == "sub-99" })
    }

    @Test func `listOfferCodes maps attributes from SDK types`() async throws {
        let stub = StubAPIClient()
        stub.willReturn(SubscriptionOfferCodesResponse(
            data: [
                AppStoreConnect_Swift_SDK.SubscriptionOfferCode(
                    type: .subscriptionOfferCodes,
                    id: "oc-1",
                    attributes: .init(
                        name: "PROMO",
                        customerEligibilities: [.new, .existing],
                        offerEligibility: .stackWithIntroOffers,
                        duration: .sixMonths,
                        offerMode: .payUpFront,
                        numberOfPeriods: 6,
                        totalNumberOfCodes: 500,
                        isActive: true
                    )
                ),
            ],
            links: .init(this: "")
        ))

        let repo = SDKSubscriptionOfferCodeRepository(client: stub)
        let result = try await repo.listOfferCodes(subscriptionId: "sub-1")

        #expect(result[0].id == "oc-1")
        #expect(result[0].name == "PROMO")
        #expect(result[0].duration == .sixMonths)
        #expect(result[0].offerMode == .payUpFront)
        #expect(result[0].numberOfPeriods == 6)
        #expect(result[0].totalNumberOfCodes == 500)
        #expect(result[0].isActive == true)
    }

    @Test func `listOfferCodes maps production and sandbox code counts`() async throws {
        let stub = StubAPIClient()
        stub.willReturn(SubscriptionOfferCodesResponse(
            data: [
                AppStoreConnect_Swift_SDK.SubscriptionOfferCode(
                    type: .subscriptionOfferCodes,
                    id: "oc-1",
                    attributes: .init(
                        name: "PROMO",
                        customerEligibilities: [.new],
                        offerEligibility: .stackWithIntroOffers,
                        duration: .oneMonth,
                        offerMode: .freeTrial,
                        numberOfPeriods: 1,
                        totalNumberOfCodes: 500,
                        productionCodeCount: 480,
                        sandboxCodeCount: 20,
                        isActive: true
                    )
                ),
            ],
            links: .init(this: "")
        ))

        let repo = SDKSubscriptionOfferCodeRepository(client: stub)
        let result = try await repo.listOfferCodes(subscriptionId: "sub-1")

        #expect(result[0].productionCodeCount == 480)
        #expect(result[0].sandboxCodeCount == 20)
    }

    // MARK: - createOfferCode

    @Test func `createOfferCode injects subscriptionId into result`() async throws {
        let stub = StubAPIClient()
        stub.willReturn(SubscriptionOfferCodeResponse(
            data: AppStoreConnect_Swift_SDK.SubscriptionOfferCode(
                type: .subscriptionOfferCodes,
                id: "oc-new",
                attributes: .init(
                    name: "LAUNCH",
                    customerEligibilities: [.new],
                    offerEligibility: .stackWithIntroOffers,
                    duration: .oneMonth,
                    offerMode: .freeTrial,
                    numberOfPeriods: 1,
                    isActive: true
                )
            ),
            links: .init(this: "")
        ))

        let repo = SDKSubscriptionOfferCodeRepository(client: stub)
        let result = try await repo.createOfferCode(
            subscriptionId: "sub-42",
            name: "LAUNCH",
            customerEligibilities: [.new],
            offerEligibility: .stackable,
            duration: .oneMonth,
            offerMode: .freeTrial,
            numberOfPeriods: 1
        )

        #expect(result.id == "oc-new")
        #expect(result.subscriptionId == "sub-42")
        #expect(result.name == "LAUNCH")
        #expect(result.duration == .oneMonth)
        #expect(result.offerMode == .freeTrial)
    }

    // MARK: - updateOfferCode

    @Test func `updateOfferCode maps response and injects empty subscriptionId`() async throws {
        let stub = StubAPIClient()
        stub.willReturn(SubscriptionOfferCodeResponse(
            data: AppStoreConnect_Swift_SDK.SubscriptionOfferCode(
                type: .subscriptionOfferCodes,
                id: "oc-1",
                attributes: .init(
                    name: "SUMMER",
                    customerEligibilities: [.new],
                    offerEligibility: .stackWithIntroOffers,
                    duration: .oneMonth,
                    offerMode: .freeTrial,
                    numberOfPeriods: 1,
                    isActive: false
                )
            ),
            links: .init(this: "")
        ))

        let repo = SDKSubscriptionOfferCodeRepository(client: stub)
        let result = try await repo.updateOfferCode(offerCodeId: "oc-1", isActive: false)

        #expect(result.id == "oc-1")
        #expect(result.isActive == false)
        // updateOfferCode doesn't know the subscriptionId — injects empty
        #expect(result.subscriptionId == "")
    }

    // MARK: - listCustomCodes

    @Test func `listCustomCodes injects offerCodeId`() async throws {
        let stub = StubAPIClient()
        stub.willReturn(SubscriptionOfferCodeCustomCodesResponse(
            data: [
                AppStoreConnect_Swift_SDK.SubscriptionOfferCodeCustomCode(
                    type: .subscriptionOfferCodeCustomCodes,
                    id: "cc-1",
                    attributes: .init(
                        customCode: "SAVE20",
                        numberOfCodes: 50,
                        expirationDate: "2025-12-31",
                        isActive: true
                    )
                ),
            ],
            links: .init(this: "")
        ))

        let repo = SDKSubscriptionOfferCodeRepository(client: stub)
        let result = try await repo.listCustomCodes(offerCodeId: "oc-10")

        #expect(result.count == 1)
        #expect(result[0].offerCodeId == "oc-10")
        #expect(result[0].customCode == "SAVE20")
        #expect(result[0].numberOfCodes == 50)
        #expect(result[0].isActive == true)
    }

    // MARK: - createCustomCode

    @Test func `createCustomCode injects offerCodeId into result`() async throws {
        let stub = StubAPIClient()
        stub.willReturn(SubscriptionOfferCodeCustomCodeResponse(
            data: AppStoreConnect_Swift_SDK.SubscriptionOfferCodeCustomCode(
                type: .subscriptionOfferCodeCustomCodes,
                id: "cc-new",
                attributes: .init(
                    customCode: "HOLIDAY",
                    numberOfCodes: 100,
                    expirationDate: "2025-06-30",
                    isActive: true
                )
            ),
            links: .init(this: "")
        ))

        let repo = SDKSubscriptionOfferCodeRepository(client: stub)
        let result = try await repo.createCustomCode(
            offerCodeId: "oc-5",
            customCode: "HOLIDAY",
            numberOfCodes: 100,
            expirationDate: "2025-06-30"
        )

        #expect(result.id == "cc-new")
        #expect(result.offerCodeId == "oc-5")
        #expect(result.customCode == "HOLIDAY")
    }

    // MARK: - updateCustomCode

    @Test func `updateCustomCode maps response and injects empty offerCodeId`() async throws {
        let stub = StubAPIClient()
        stub.willReturn(SubscriptionOfferCodeCustomCodeResponse(
            data: AppStoreConnect_Swift_SDK.SubscriptionOfferCodeCustomCode(
                type: .subscriptionOfferCodeCustomCodes,
                id: "cc-1",
                attributes: .init(
                    customCode: "SAVE20",
                    numberOfCodes: 50,
                    isActive: false
                )
            ),
            links: .init(this: "")
        ))

        let repo = SDKSubscriptionOfferCodeRepository(client: stub)
        let result = try await repo.updateCustomCode(customCodeId: "cc-1", isActive: false)

        #expect(result.id == "cc-1")
        #expect(result.isActive == false)
        #expect(result.offerCodeId == "")
    }

    // MARK: - listOneTimeUseCodes

    @Test func `listOneTimeUseCodes injects offerCodeId`() async throws {
        let stub = StubAPIClient()
        stub.willReturn(SubscriptionOfferCodeOneTimeUseCodesResponse(
            data: [
                AppStoreConnect_Swift_SDK.SubscriptionOfferCodeOneTimeUseCode(
                    type: .subscriptionOfferCodeOneTimeUseCodes,
                    id: "otc-1",
                    attributes: .init(
                        numberOfCodes: 1000,
                        expirationDate: "2025-12-31",
                        isActive: true
                    )
                ),
            ],
            links: .init(this: "")
        ))

        let repo = SDKSubscriptionOfferCodeRepository(client: stub)
        let result = try await repo.listOneTimeUseCodes(offerCodeId: "oc-20")

        #expect(result.count == 1)
        #expect(result[0].offerCodeId == "oc-20")
        #expect(result[0].numberOfCodes == 1000)
        #expect(result[0].isActive == true)
    }

    // MARK: - createOneTimeUseCode

    @Test func `createOneTimeUseCode injects offerCodeId into result`() async throws {
        let stub = StubAPIClient()
        stub.willReturn(SubscriptionOfferCodeOneTimeUseCodeResponse(
            data: AppStoreConnect_Swift_SDK.SubscriptionOfferCodeOneTimeUseCode(
                type: .subscriptionOfferCodeOneTimeUseCodes,
                id: "otc-new",
                attributes: .init(
                    numberOfCodes: 500,
                    expirationDate: "2026-01-01",
                    isActive: true
                )
            ),
            links: .init(this: "")
        ))

        let repo = SDKSubscriptionOfferCodeRepository(client: stub)
        let result = try await repo.createOneTimeUseCode(
            offerCodeId: "oc-7",
            numberOfCodes: 500,
            expirationDate: "2026-01-01",
            environment: .production
        )

        #expect(result.id == "otc-new")
        #expect(result.offerCodeId == "oc-7")
        #expect(result.numberOfCodes == 500)
    }

    @Test func `createOneTimeUseCode maps environment from SDK response`() async throws {
        let stub = StubAPIClient()
        stub.willReturn(SubscriptionOfferCodeOneTimeUseCodeResponse(
            data: AppStoreConnect_Swift_SDK.SubscriptionOfferCodeOneTimeUseCode(
                type: .subscriptionOfferCodeOneTimeUseCodes,
                id: "otc-sb",
                attributes: .init(
                    numberOfCodes: 10,
                    expirationDate: "2026-01-01",
                    isActive: true,
                    environment: .sandbox
                )
            ),
            links: .init(this: "")
        ))

        let repo = SDKSubscriptionOfferCodeRepository(client: stub)
        let result = try await repo.createOneTimeUseCode(
            offerCodeId: "oc-7",
            numberOfCodes: 10,
            expirationDate: "2026-01-01",
            environment: .sandbox
        )

        #expect(result.environment == .sandbox)
    }

    // MARK: - updateOneTimeUseCode

    @Test func `updateOneTimeUseCode maps response and injects empty offerCodeId`() async throws {
        let stub = StubAPIClient()
        stub.willReturn(SubscriptionOfferCodeOneTimeUseCodeResponse(
            data: AppStoreConnect_Swift_SDK.SubscriptionOfferCodeOneTimeUseCode(
                type: .subscriptionOfferCodeOneTimeUseCodes,
                id: "otc-1",
                attributes: .init(
                    numberOfCodes: 1000,
                    isActive: false
                )
            ),
            links: .init(this: "")
        ))

        let repo = SDKSubscriptionOfferCodeRepository(client: stub)
        let result = try await repo.updateOneTimeUseCode(oneTimeCodeId: "otc-1", isActive: false)

        #expect(result.id == "otc-1")
        #expect(result.isActive == false)
        #expect(result.offerCodeId == "")
    }

    @Test func `listPrices injects offerCodeId and maps territory + subscriptionPricePoint`() async throws {
        let stub = StubAPIClient()
        stub.willReturn(SubscriptionOfferCodePricesResponse(
            data: [
                AppStoreConnect_Swift_SDK.SubscriptionOfferCodePrice(
                    type: .subscriptionOfferCodePrices, id: "p-1",
                    relationships: .init(
                        territory: .init(data: .init(type: .territories, id: "USA")),
                        subscriptionPricePoint: .init(data: .init(type: .subscriptionPricePoints, id: "spp-9"))
                    )
                ),
            ],
            links: .init(this: "")
        ))

        let repo = SDKSubscriptionOfferCodeRepository(client: stub)
        let result = try await repo.listPrices(offerCodeId: "oc-77")

        #expect(result[0].offerCodeId == "oc-77")
        #expect(result[0].territory == "USA")
        #expect(result[0].subscriptionPricePointId == "spp-9")
    }

    @Test func `fetchOneTimeUseCodeValues returns CSV string from SDK`() async throws {
        let stub = StubAPIClient()
        stub.willReturn("ABC\nDEF\n")
        let repo = SDKSubscriptionOfferCodeRepository(client: stub)
        let result = try await repo.fetchOneTimeUseCodeValues(oneTimeCodeId: "otc-1")
        #expect(result == "ABC\nDEF\n")
    }
}
