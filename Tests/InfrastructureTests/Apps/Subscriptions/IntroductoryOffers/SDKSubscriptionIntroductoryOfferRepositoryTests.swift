@preconcurrency import AppStoreConnect_Swift_SDK
import Testing
@testable import Infrastructure
@testable import Domain

@Suite
struct SDKSubscriptionIntroductoryOfferRepositoryTests {

    // MARK: - listIntroductoryOffers

    @Test func `listIntroductoryOffers injects subscriptionId into each offer`() async throws {
        let stub = StubAPIClient()
        stub.willReturn(SubscriptionIntroductoryOffersResponse(
            data: [
                AppStoreConnect_Swift_SDK.SubscriptionIntroductoryOffer(
                    type: .subscriptionIntroductoryOffers,
                    id: "offer-1",
                    attributes: .init(duration: .oneMonth, offerMode: .freeTrial, numberOfPeriods: 1)
                ),
                AppStoreConnect_Swift_SDK.SubscriptionIntroductoryOffer(
                    type: .subscriptionIntroductoryOffers,
                    id: "offer-2",
                    attributes: .init(duration: .oneYear, offerMode: .payAsYouGo, numberOfPeriods: 3)
                ),
            ],
            links: .init(this: "")
        ))

        let repo = SDKSubscriptionIntroductoryOfferRepository(client: stub)
        let result = try await repo.listIntroductoryOffers(subscriptionId: "sub-99")

        #expect(result.count == 2)
        #expect(result.allSatisfy { $0.subscriptionId == "sub-99" })
    }

    @Test func `listIntroductoryOffers maps duration and offerMode from SDK attributes`() async throws {
        let stub = StubAPIClient()
        stub.willReturn(SubscriptionIntroductoryOffersResponse(
            data: [
                AppStoreConnect_Swift_SDK.SubscriptionIntroductoryOffer(
                    type: .subscriptionIntroductoryOffers,
                    id: "offer-1",
                    attributes: .init(duration: .sixMonths, offerMode: .payUpFront, numberOfPeriods: 6)
                ),
            ],
            links: .init(this: "")
        ))

        let repo = SDKSubscriptionIntroductoryOfferRepository(client: stub)
        let result = try await repo.listIntroductoryOffers(subscriptionId: "sub-1")

        #expect(result[0].duration == .sixMonths)
        #expect(result[0].offerMode == .payUpFront)
        #expect(result[0].numberOfPeriods == 6)
    }

    @Test func `listIntroductoryOffers extracts territory from relationships`() async throws {
        let stub = StubAPIClient()
        stub.willReturn(SubscriptionIntroductoryOffersResponse(
            data: [
                AppStoreConnect_Swift_SDK.SubscriptionIntroductoryOffer(
                    type: .subscriptionIntroductoryOffers,
                    id: "offer-1",
                    attributes: .init(duration: .oneMonth, offerMode: .freeTrial, numberOfPeriods: 1),
                    relationships: .init(territory: .init(data: .init(type: .territories, id: "USA")))
                ),
            ],
            links: .init(this: "")
        ))

        let repo = SDKSubscriptionIntroductoryOfferRepository(client: stub)
        let result = try await repo.listIntroductoryOffers(subscriptionId: "sub-1")

        #expect(result[0].territory == "USA")
    }

    // MARK: - createIntroductoryOffer

    @Test func `createIntroductoryOffer injects subscriptionId into result`() async throws {
        let stub = StubAPIClient()
        stub.willReturn(SubscriptionIntroductoryOfferResponse(
            data: AppStoreConnect_Swift_SDK.SubscriptionIntroductoryOffer(
                type: .subscriptionIntroductoryOffers,
                id: "offer-new",
                attributes: .init(duration: .oneMonth, offerMode: .freeTrial, numberOfPeriods: 1)
            ),
            links: .init(this: "")
        ))

        let repo = SDKSubscriptionIntroductoryOfferRepository(client: stub)
        let result = try await repo.createIntroductoryOffer(
            subscriptionId: "sub-42",
            duration: .oneMonth,
            offerMode: .freeTrial,
            numberOfPeriods: 1,
            startDate: nil,
            endDate: nil,
            territory: nil,
            pricePointId: nil
        )

        #expect(result.id == "offer-new")
        #expect(result.subscriptionId == "sub-42")
        #expect(result.duration == .oneMonth)
        #expect(result.offerMode == .freeTrial)
    }

    @Test func `deleteIntroductoryOffer performs void request`() async throws {
        let stub = StubAPIClient()
        let repo = SDKSubscriptionIntroductoryOfferRepository(client: stub)
        try await repo.deleteIntroductoryOffer(offerId: "offer-1")
        #expect(stub.voidRequestCalled == true)
    }
}
