@preconcurrency import AppStoreConnect_Swift_SDK
import Testing
@testable import Infrastructure
@testable import Domain

@Suite
struct SDKInAppPurchaseRepositoryTests {

    // MARK: - listInAppPurchases

    @Test func `listInAppPurchases injects appId into each purchase`() async throws {
        let stub = StubAPIClient()
        stub.willReturn(InAppPurchasesV2Response(
            data: [
                InAppPurchaseV2(type: .inAppPurchases, id: "iap-1", attributes: .init(name: "Gold Coins", productID: "com.app.gold", inAppPurchaseType: .consumable)),
                InAppPurchaseV2(type: .inAppPurchases, id: "iap-2", attributes: .init(name: "Remove Ads", productID: "com.app.ads", inAppPurchaseType: .nonConsumable)),
            ],
            links: .init(this: "")
        ))

        let repo = SDKInAppPurchaseRepository(client: stub)
        let result = try await repo.listInAppPurchases(appId: "app-99", limit: nil)

        #expect(result.data.count == 2)
        #expect(result.data.allSatisfy { $0.appId == "app-99" })
    }

    @Test func `listInAppPurchases maps id and referenceName from SDK response`() async throws {
        let stub = StubAPIClient()
        stub.willReturn(InAppPurchasesV2Response(
            data: [
                InAppPurchaseV2(type: .inAppPurchases, id: "iap-abc", attributes: .init(name: "Gold Coins", productID: "com.app.gold")),
            ],
            links: .init(this: "")
        ))

        let repo = SDKInAppPurchaseRepository(client: stub)
        let result = try await repo.listInAppPurchases(appId: "app-1", limit: nil)

        #expect(result.data[0].id == "iap-abc")
        #expect(result.data[0].referenceName == "Gold Coins")
        #expect(result.data[0].productId == "com.app.gold")
    }

    @Test func `listInAppPurchases maps consumable type`() async throws {
        let stub = StubAPIClient()
        stub.willReturn(InAppPurchasesV2Response(
            data: [InAppPurchaseV2(type: .inAppPurchases, id: "iap-1", attributes: .init(inAppPurchaseType: .consumable))],
            links: .init(this: "")
        ))

        let repo = SDKInAppPurchaseRepository(client: stub)
        let result = try await repo.listInAppPurchases(appId: "app-1", limit: nil)

        #expect(result.data[0].type == .consumable)
    }

    @Test func `listInAppPurchases maps nonConsumable type`() async throws {
        let stub = StubAPIClient()
        stub.willReturn(InAppPurchasesV2Response(
            data: [InAppPurchaseV2(type: .inAppPurchases, id: "iap-1", attributes: .init(inAppPurchaseType: .nonConsumable))],
            links: .init(this: "")
        ))

        let repo = SDKInAppPurchaseRepository(client: stub)
        let result = try await repo.listInAppPurchases(appId: "app-1", limit: nil)

        #expect(result.data[0].type == .nonConsumable)
    }

    @Test func `listInAppPurchases maps reviewNote from SDK attributes`() async throws {
        let stub = StubAPIClient()
        stub.willReturn(InAppPurchasesV2Response(
            data: [InAppPurchaseV2(type: .inAppPurchases, id: "iap-1", attributes: .init(reviewNote: "Use code TEST"))],
            links: .init(this: "")
        ))

        let repo = SDKInAppPurchaseRepository(client: stub)
        let result = try await repo.listInAppPurchases(appId: "app-1", limit: nil)

        #expect(result.data[0].reviewNote == "Use code TEST")
    }

    @Test func `listInAppPurchases maps nil reviewNote when SDK omits it`() async throws {
        let stub = StubAPIClient()
        stub.willReturn(InAppPurchasesV2Response(
            data: [InAppPurchaseV2(type: .inAppPurchases, id: "iap-1", attributes: .init(name: "Gold"))],
            links: .init(this: "")
        ))

        let repo = SDKInAppPurchaseRepository(client: stub)
        let result = try await repo.listInAppPurchases(appId: "app-1", limit: nil)

        #expect(result.data[0].reviewNote == nil)
    }

    @Test func `listInAppPurchases maps state from SDK response`() async throws {
        let stub = StubAPIClient()
        stub.willReturn(InAppPurchasesV2Response(
            data: [InAppPurchaseV2(type: .inAppPurchases, id: "iap-1", attributes: .init(state: .missingMetadata))],
            links: .init(this: "")
        ))

        let repo = SDKInAppPurchaseRepository(client: stub)
        let result = try await repo.listInAppPurchases(appId: "app-1", limit: nil)

        #expect(result.data[0].state == .missingMetadata)
    }

    // MARK: - createInAppPurchase

    @Test func `createInAppPurchase injects appId into response`() async throws {
        let stub = StubAPIClient()
        stub.willReturn(InAppPurchaseV2Response(
            data: InAppPurchaseV2(
                type: .inAppPurchases,
                id: "iap-new",
                attributes: .init(name: "Gold Coins", productID: "com.app.gold", inAppPurchaseType: .consumable)
            ),
            links: .init(this: "")
        ))

        let repo = SDKInAppPurchaseRepository(client: stub)
        let result = try await repo.createInAppPurchase(
            appId: "app-42",
            referenceName: "Gold Coins",
            productId: "com.app.gold",
            type: .consumable
        )

        #expect(result.id == "iap-new")
        #expect(result.appId == "app-42")
        #expect(result.referenceName == "Gold Coins")
    }

    @Test func `createInAppPurchase maps type from SDK response`() async throws {
        let stub = StubAPIClient()
        stub.willReturn(InAppPurchaseV2Response(
            data: InAppPurchaseV2(
                type: .inAppPurchases,
                id: "iap-new",
                attributes: .init(inAppPurchaseType: .nonRenewingSubscription)
            ),
            links: .init(this: "")
        ))

        let repo = SDKInAppPurchaseRepository(client: stub)
        let result = try await repo.createInAppPurchase(
            appId: "app-1",
            referenceName: "Subscription",
            productId: "com.app.sub",
            type: .nonRenewingSubscription
        )

        #expect(result.type == .nonRenewingSubscription)
    }

    @Test func `createInAppPurchase throws for freeSubscription type`() async throws {
        let stub = StubAPIClient()
        let repo = SDKInAppPurchaseRepository(client: stub)
        await #expect(throws: (any Error).self) {
            try await repo.createInAppPurchase(
                appId: "app-1",
                referenceName: "Free",
                productId: "com.app.free",
                type: .freeSubscription
            )
        }
    }

    // MARK: - updateInAppPurchase

    @Test func `updateInAppPurchase returns updated record with empty appId`() async throws {
        let stub = StubAPIClient()
        stub.willReturn(InAppPurchaseV2Response(
            data: InAppPurchaseV2(
                type: .inAppPurchases, id: "iap-1",
                attributes: .init(name: "Renamed", productID: "com.app.gold", inAppPurchaseType: .consumable)
            ),
            links: .init(this: "")
        ))

        let repo = SDKInAppPurchaseRepository(client: stub)
        let result = try await repo.updateInAppPurchase(
            iapId: "iap-1", referenceName: "Renamed", reviewNote: "Note", isFamilySharable: true
        )

        #expect(result.id == "iap-1")
        #expect(result.referenceName == "Renamed")
        #expect(result.appId == "")
    }

    // MARK: - deleteInAppPurchase

    @Test func `deleteInAppPurchase performs void request`() async throws {
        let stub = StubAPIClient()
        let repo = SDKInAppPurchaseRepository(client: stub)
        try await repo.deleteInAppPurchase(iapId: "iap-1")
        #expect(stub.voidRequestCalled == true)
    }
}
