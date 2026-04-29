@preconcurrency import AppStoreConnect_Swift_SDK
import Testing
@testable import Infrastructure
@testable import Domain

@Suite
struct SDKSubscriptionRepositoryTests {

    // MARK: - listSubscriptions

    @Test func `listSubscriptions injects groupId into each subscription`() async throws {
        let stub = StubAPIClient()
        stub.willReturn(SubscriptionsResponse(
            data: [
                AppStoreConnect_Swift_SDK.Subscription(type: .subscriptions, id: "sub-1", attributes: .init(name: "Monthly", subscriptionPeriod: .oneMonth)),
                AppStoreConnect_Swift_SDK.Subscription(type: .subscriptions, id: "sub-2", attributes: .init(name: "Annual", subscriptionPeriod: .oneYear)),
            ],
            links: .init(this: "")
        ))

        let repo = SDKSubscriptionRepository(client: stub)
        let result = try await repo.listSubscriptions(groupId: "grp-99", limit: nil)

        #expect(result.data.count == 2)
        #expect(result.data.allSatisfy { $0.groupId == "grp-99" })
    }

    @Test func `listSubscriptions maps name and productId from SDK response`() async throws {
        let stub = StubAPIClient()
        stub.willReturn(SubscriptionsResponse(
            data: [
                AppStoreConnect_Swift_SDK.Subscription(type: .subscriptions, id: "sub-1", attributes: .init(name: "Monthly Premium", productID: "com.app.monthly")),
            ],
            links: .init(this: "")
        ))

        let repo = SDKSubscriptionRepository(client: stub)
        let result = try await repo.listSubscriptions(groupId: "grp-1", limit: nil)

        #expect(result.data[0].id == "sub-1")
        #expect(result.data[0].name == "Monthly Premium")
        #expect(result.data[0].productId == "com.app.monthly")
    }

    @Test func `listSubscriptions maps subscriptionPeriod from SDK attributes`() async throws {
        let stub = StubAPIClient()
        stub.willReturn(SubscriptionsResponse(
            data: [
                AppStoreConnect_Swift_SDK.Subscription(type: .subscriptions, id: "sub-1", attributes: .init(subscriptionPeriod: .oneMonth)),
            ],
            links: .init(this: "")
        ))

        let repo = SDKSubscriptionRepository(client: stub)
        let result = try await repo.listSubscriptions(groupId: "grp-1", limit: nil)

        #expect(result.data[0].subscriptionPeriod == .oneMonth)
    }

    @Test func `listSubscriptions maps reviewNote from SDK attributes`() async throws {
        let stub = StubAPIClient()
        stub.willReturn(SubscriptionsResponse(
            data: [
                AppStoreConnect_Swift_SDK.Subscription(type: .subscriptions, id: "sub-1", attributes: .init(reviewNote: "Use code TEST")),
            ],
            links: .init(this: "")
        ))

        let repo = SDKSubscriptionRepository(client: stub)
        let result = try await repo.listSubscriptions(groupId: "grp-1", limit: nil)

        #expect(result.data[0].reviewNote == "Use code TEST")
    }

    @Test func `listSubscriptions maps nil reviewNote when SDK omits it`() async throws {
        let stub = StubAPIClient()
        stub.willReturn(SubscriptionsResponse(
            data: [
                AppStoreConnect_Swift_SDK.Subscription(type: .subscriptions, id: "sub-1", attributes: .init(name: "Monthly")),
            ],
            links: .init(this: "")
        ))

        let repo = SDKSubscriptionRepository(client: stub)
        let result = try await repo.listSubscriptions(groupId: "grp-1", limit: nil)

        #expect(result.data[0].reviewNote == nil)
    }

    @Test func `listSubscriptions maps isFamilySharable from SDK attributes`() async throws {
        let stub = StubAPIClient()
        stub.willReturn(SubscriptionsResponse(
            data: [
                AppStoreConnect_Swift_SDK.Subscription(type: .subscriptions, id: "sub-1", attributes: .init(isFamilySharable: true)),
            ],
            links: .init(this: "")
        ))

        let repo = SDKSubscriptionRepository(client: stub)
        let result = try await repo.listSubscriptions(groupId: "grp-1", limit: nil)

        #expect(result.data[0].isFamilySharable == true)
    }

    // MARK: - createSubscription

    @Test func `createSubscription injects groupId into response`() async throws {
        let stub = StubAPIClient()
        stub.willReturn(SubscriptionResponse(
            data: AppStoreConnect_Swift_SDK.Subscription(
                type: .subscriptions,
                id: "sub-new",
                attributes: .init(name: "Monthly Premium", productID: "com.app.monthly", subscriptionPeriod: .oneMonth)
            ),
            links: .init(this: "")
        ))

        let repo = SDKSubscriptionRepository(client: stub)
        let result = try await repo.createSubscription(
            groupId: "grp-42",
            name: "Monthly Premium",
            productId: "com.app.monthly",
            period: .oneMonth,
            isFamilySharable: false,
            groupLevel: nil
        )

        #expect(result.id == "sub-new")
        #expect(result.groupId == "grp-42")
        #expect(result.name == "Monthly Premium")
    }

    @Test func `createSubscription maps period from SDK response`() async throws {
        let stub = StubAPIClient()
        stub.willReturn(SubscriptionResponse(
            data: AppStoreConnect_Swift_SDK.Subscription(
                type: .subscriptions,
                id: "sub-new",
                attributes: .init(subscriptionPeriod: .oneYear)
            ),
            links: .init(this: "")
        ))

        let repo = SDKSubscriptionRepository(client: stub)
        let result = try await repo.createSubscription(
            groupId: "grp-1",
            name: "Annual",
            productId: "com.app.annual",
            period: .oneYear,
            isFamilySharable: false,
            groupLevel: nil
        )

        #expect(result.subscriptionPeriod == .oneYear)
    }

    // MARK: - updateSubscription

    @Test func `updateSubscription returns updated record with empty groupId`() async throws {
        let stub = StubAPIClient()
        stub.willReturn(SubscriptionResponse(
            data: AppStoreConnect_Swift_SDK.Subscription(
                type: .subscriptions, id: "sub-1",
                attributes: .init(
                    name: "Renamed",
                    productID: "com.app.monthly",
                    isFamilySharable: true,
                    subscriptionPeriod: .oneMonth,
                    groupLevel: 3
                )
            ),
            links: .init(this: "")
        ))

        let repo = SDKSubscriptionRepository(client: stub)
        let result = try await repo.updateSubscription(
            subscriptionId: "sub-1", name: "Renamed",
            isFamilySharable: true, groupLevel: 3,
            subscriptionPeriod: nil, reviewNote: nil
        )

        #expect(result.id == "sub-1")
        #expect(result.name == "Renamed")
        #expect(result.isFamilySharable == true)
        #expect(result.groupLevel == 3)
        #expect(result.groupId == "")
    }

    // MARK: - deleteSubscription

    @Test func `deleteSubscription performs void request`() async throws {
        let stub = StubAPIClient()
        let repo = SDKSubscriptionRepository(client: stub)
        try await repo.deleteSubscription(subscriptionId: "sub-1")
        #expect(stub.voidRequestCalled == true)
    }
}
