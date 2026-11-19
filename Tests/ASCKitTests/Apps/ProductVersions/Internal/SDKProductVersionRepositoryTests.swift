@preconcurrency import AppStoreConnect_Swift_SDK
import Testing
@testable import ASCKit

@Suite
struct SDKProductVersionRepositoryTests {

    @Test func `in-app purchase versions carry their IAP id, version number and state`() async throws {
        let stub = StubAPIClient()
        stub.willReturn(InAppPurchaseVersionsResponse(
            data: [
                InAppPurchaseVersion(type: .inAppPurchaseVersions, id: "iv-1",
                                     attributes: .init(version: 1, state: .prepareForSubmission)),
            ],
            links: .init(this: "")
        ))

        let repo = SDKProductVersionRepository(client: stub)
        let versions = try await repo.listInAppPurchaseVersions(iapId: "iap-7")

        #expect(versions == [
            ProductVersion(id: "iv-1", productId: "iap-7", kind: .inAppPurchase, version: 1, state: .prepareForSubmission),
        ])
        #expect(stub.lastPath == "/v2/inAppPurchases/iap-7/versions")
    }

    @Test func `subscription versions carry their subscription id, version number and state`() async throws {
        let stub = StubAPIClient()
        stub.willReturn(SubscriptionVersionsResponse(
            data: [
                SubscriptionVersion(type: .subscriptionVersions, id: "sv-2",
                                    attributes: .init(version: 2, state: .approved)),
            ],
            links: .init(this: "")
        ))

        let repo = SDKProductVersionRepository(client: stub)
        let versions = try await repo.listSubscriptionVersions(subscriptionId: "sub-7")

        #expect(versions == [
            ProductVersion(id: "sv-2", productId: "sub-7", kind: .subscription, version: 2, state: .approved),
        ])
        #expect(stub.lastPath == "/v1/subscriptions/sub-7/versions")
    }

    @Test func `subscription group versions carry their group id, version number and state`() async throws {
        let stub = StubAPIClient()
        stub.willReturn(SubscriptionGroupVersionsResponse(
            data: [
                SubscriptionGroupVersion(type: .subscriptionGroupVersions, id: "gv-1",
                                         attributes: .init(version: 1, state: .waitingForReview)),
            ],
            links: .init(this: "")
        ))

        let repo = SDKProductVersionRepository(client: stub)
        let versions = try await repo.listSubscriptionGroupVersions(groupId: "grp-7")

        #expect(versions == [
            ProductVersion(id: "gv-1", productId: "grp-7", kind: .subscriptionGroup, version: 1, state: .waitingForReview),
        ])
        #expect(stub.lastPath == "/v1/subscriptionGroups/grp-7/versions")
    }

    @Test func `version lists include every version beyond the first page`() async throws {
        func page(_ range: Range<Int>, nextCursor: String?) -> SubscriptionVersionsResponse {
            SubscriptionVersionsResponse(
                data: range.map { SubscriptionVersion(type: .subscriptionVersions, id: "sv-\($0)",
                                                      attributes: .init(version: $0, state: .replacedWithNewVersion)) },
                links: .init(this: ""),
                meta: .init(paging: .init(total: 75, limit: 50, nextCursor: nextCursor))
            )
        }
        let stub = StubAPIClient()
        stub.willReturnPages([page(0..<50, nextCursor: "page-2"), page(50..<75, nextCursor: nil)])

        let repo = SDKProductVersionRepository(client: stub)
        let versions = try await repo.listSubscriptionVersions(subscriptionId: "sub-7")

        #expect(versions.count == 75)
        #expect(versions.last?.id == "sv-74")
    }
}
