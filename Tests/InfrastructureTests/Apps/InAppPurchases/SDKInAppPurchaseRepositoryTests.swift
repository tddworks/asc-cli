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

    // MARK: - First-time submission detection

    @Test func `listInAppPurchases marks every unapproved IAP first-time when batch has no approved siblings`() async throws {
        // No IAP in this app has ever been approved → Apple requires first IAP to ride along
        // with a new App Store version → every unapproved IAP gets the iris-routed submit
        // affordance via isFirstTimeSubmission == true.
        let stub = StubAPIClient()
        stub.willReturn(InAppPurchasesV2Response(
            data: [
                InAppPurchaseV2(type: .inAppPurchases, id: "iap-1", attributes: .init(state: .readyToSubmit)),
                InAppPurchaseV2(type: .inAppPurchases, id: "iap-2", attributes: .init(state: .missingMetadata)),
            ],
            links: .init(this: "")
        ))

        let repo = SDKInAppPurchaseRepository(client: stub)
        let result = try await repo.listInAppPurchases(appId: "app-1", limit: nil)

        #expect(result.data.allSatisfy { $0.isFirstTimeSubmission == true })
    }

    @Test func `listInAppPurchases marks every IAP not first-time when at least one sibling is approved`() async throws {
        // App already has an approved IAP → first-IAP gate is cleared → every other IAP
        // can submit via the public-key path.
        let stub = StubAPIClient()
        stub.willReturn(InAppPurchasesV2Response(
            data: [
                InAppPurchaseV2(type: .inAppPurchases, id: "iap-shipped", attributes: .init(state: .approved)),
                InAppPurchaseV2(type: .inAppPurchases, id: "iap-new", attributes: .init(state: .readyToSubmit)),
            ],
            links: .init(this: "")
        ))

        let repo = SDKInAppPurchaseRepository(client: stub)
        let result = try await repo.listInAppPurchases(appId: "app-1", limit: nil)

        #expect(result.data.allSatisfy { $0.isFirstTimeSubmission == false })
    }

    @Test func `listInAppPurchases treats removedFromSale as already-shipped`() async throws {
        // Once Apple has approved an IAP, removing it from sale doesn't reopen the
        // first-IAP gate — the app has cleared review for IAPs at least once.
        let stub = StubAPIClient()
        stub.willReturn(InAppPurchasesV2Response(
            data: [
                InAppPurchaseV2(type: .inAppPurchases, id: "iap-removed", attributes: .init(state: .removedFromSale)),
                InAppPurchaseV2(type: .inAppPurchases, id: "iap-new", attributes: .init(state: .readyToSubmit)),
            ],
            links: .init(this: "")
        ))

        let repo = SDKInAppPurchaseRepository(client: stub)
        let result = try await repo.listInAppPurchases(appId: "app-1", limit: nil)

        let newIAP = try #require(result.data.first { $0.id == "iap-new" })
        #expect(newIAP.isFirstTimeSubmission == false)
    }

    @Test func `listInAppPurchases marks empty batch entries first-time vacuously not applied`() async throws {
        // Edge case: empty batch. Nothing to mark; stays empty.
        let stub = StubAPIClient()
        stub.willReturn(InAppPurchasesV2Response(data: [], links: .init(this: "")))

        let repo = SDKInAppPurchaseRepository(client: stub)
        let result = try await repo.listInAppPurchases(appId: "app-1", limit: nil)

        #expect(result.data.isEmpty)
    }

    // MARK: - Iris-state enrichment

    @Test func `listInAppPurchases threads submitWithNextAppStoreVersion from the iris enricher`() async throws {
        let stub = StubAPIClient()
        stub.willReturn(InAppPurchasesV2Response(
            data: [
                InAppPurchaseV2(type: .inAppPurchases, id: "iap-1", attributes: .init(state: .readyToSubmit)),
                InAppPurchaseV2(type: .inAppPurchases, id: "iap-2", attributes: .init(state: .readyToSubmit)),
            ],
            links: .init(this: "")
        ))

        // The enricher closure represents "ask iris for submitWithNextAppStoreVersion
        // per IAP". We stub it directly here so the SDK repo stays decoupled from
        // iris cookies / network.
        let enricher: @Sendable (String) async -> [String: Bool] = { _ in
            ["iap-1": true, "iap-2": false]
        }

        let repo = SDKInAppPurchaseRepository(client: stub, irisFlagsProvider: enricher)
        let result = try await repo.listInAppPurchases(appId: "app-1", limit: nil)

        let iap1 = try #require(result.data.first { $0.id == "iap-1" })
        let iap2 = try #require(result.data.first { $0.id == "iap-2" })
        #expect(iap1.submitWithNextAppStoreVersion == true)
        #expect(iap2.submitWithNextAppStoreVersion == false)
    }

    @Test func `listInAppPurchases falls back to false when no iris enricher is wired`() async throws {
        // Default constructor — no enricher. CI scripts using API-key auth get the
        // existing behavior unchanged: every IAP has submitWithNextAppStoreVersion=false.
        let stub = StubAPIClient()
        stub.willReturn(InAppPurchasesV2Response(
            data: [InAppPurchaseV2(type: .inAppPurchases, id: "iap-1", attributes: .init(state: .readyToSubmit))],
            links: .init(this: "")
        ))

        let repo = SDKInAppPurchaseRepository(client: stub)
        let result = try await repo.listInAppPurchases(appId: "app-1", limit: nil)

        #expect(result.data[0].submitWithNextAppStoreVersion == false)
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
