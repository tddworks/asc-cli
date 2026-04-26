@preconcurrency import AppStoreConnect_Swift_SDK
import Testing
@testable import Infrastructure
@testable import Domain

@Suite
struct SDKPromotedPurchaseRepositoryTests {

    @Test func `listPromotedPurchases injects appId into each item`() async throws {
        let stub = StubAPIClient()
        stub.willReturn(PromotedPurchasesResponse(
            data: [
                AppStoreConnect_Swift_SDK.PromotedPurchase(
                    type: .promotedPurchases, id: "pp-1",
                    attributes: .init(isVisibleForAllUsers: true, isEnabled: true)
                ),
                AppStoreConnect_Swift_SDK.PromotedPurchase(
                    type: .promotedPurchases, id: "pp-2",
                    attributes: .init(isVisibleForAllUsers: false, isEnabled: false)
                ),
            ],
            links: .init(this: "")
        ))

        let repo = SDKPromotedPurchaseRepository(client: stub)
        let result = try await repo.listPromotedPurchases(appId: "app-99", limit: nil)

        #expect(result.data.count == 2)
        #expect(result.data.allSatisfy { $0.appId == "app-99" })
    }

    @Test func `listPromotedPurchases maps state and isVisibleForAllUsers`() async throws {
        let stub = StubAPIClient()
        stub.willReturn(PromotedPurchasesResponse(
            data: [
                AppStoreConnect_Swift_SDK.PromotedPurchase(
                    type: .promotedPurchases, id: "pp-1",
                    attributes: .init(isVisibleForAllUsers: true, isEnabled: false, state: .approved)
                ),
            ],
            links: .init(this: "")
        ))

        let repo = SDKPromotedPurchaseRepository(client: stub)
        let result = try await repo.listPromotedPurchases(appId: "app-1", limit: nil)

        #expect(result.data[0].state == .approved)
        #expect(result.data[0].isVisibleForAllUsers == true)
        #expect(result.data[0].isEnabled == false)
    }

    @Test func `listPromotedPurchases maps inAppPurchaseId from relationships`() async throws {
        let stub = StubAPIClient()
        stub.willReturn(PromotedPurchasesResponse(
            data: [
                AppStoreConnect_Swift_SDK.PromotedPurchase(
                    type: .promotedPurchases, id: "pp-1",
                    attributes: .init(isVisibleForAllUsers: true, isEnabled: true),
                    relationships: .init(
                        inAppPurchaseV2: .init(data: .init(type: .inAppPurchases, id: "iap-1"))
                    )
                ),
            ],
            links: .init(this: "")
        ))

        let repo = SDKPromotedPurchaseRepository(client: stub)
        let result = try await repo.listPromotedPurchases(appId: "app-1", limit: nil)

        #expect(result.data[0].inAppPurchaseId == "iap-1")
        #expect(result.data[0].subscriptionId == nil)
    }

    @Test func `createPromotedPurchase with iapId injects appId and IAP relationship`() async throws {
        let stub = StubAPIClient()
        stub.willReturn(PromotedPurchaseResponse(
            data: AppStoreConnect_Swift_SDK.PromotedPurchase(
                type: .promotedPurchases, id: "pp-new",
                attributes: .init(isVisibleForAllUsers: true, isEnabled: true),
                relationships: .init(inAppPurchaseV2: .init(data: .init(type: .inAppPurchases, id: "iap-1")))
            ),
            links: .init(this: "")
        ))

        let repo = SDKPromotedPurchaseRepository(client: stub)
        let result = try await repo.createPromotedPurchase(
            appId: "app-42", isVisibleForAllUsers: true, isEnabled: true,
            inAppPurchaseId: "iap-1", subscriptionId: nil
        )

        #expect(result.id == "pp-new")
        #expect(result.appId == "app-42")
        #expect(result.inAppPurchaseId == "iap-1")
    }

    @Test func `updatePromotedPurchase returns updated record with empty appId`() async throws {
        let stub = StubAPIClient()
        stub.willReturn(PromotedPurchaseResponse(
            data: AppStoreConnect_Swift_SDK.PromotedPurchase(
                type: .promotedPurchases, id: "pp-1",
                attributes: .init(isVisibleForAllUsers: false, isEnabled: false)
            ),
            links: .init(this: "")
        ))

        let repo = SDKPromotedPurchaseRepository(client: stub)
        let result = try await repo.updatePromotedPurchase(
            promotedId: "pp-1", isVisibleForAllUsers: false, isEnabled: false
        )

        #expect(result.id == "pp-1")
        #expect(result.appId == "")
    }

    @Test func `deletePromotedPurchase performs void request`() async throws {
        let stub = StubAPIClient()
        let repo = SDKPromotedPurchaseRepository(client: stub)
        try await repo.deletePromotedPurchase(promotedId: "pp-1")
        #expect(stub.voidRequestCalled == true)
    }
}
