@preconcurrency import AppStoreConnect_Swift_SDK
import Testing
@testable import Infrastructure
@testable import Domain

@Suite
struct SDKSubscriptionGroupLocalizationRepositoryTests {

    @Test func `listLocalizations injects groupId into each item`() async throws {
        let stub = StubAPIClient()
        stub.willReturn(SubscriptionGroupLocalizationsResponse(
            data: [
                AppStoreConnect_Swift_SDK.SubscriptionGroupLocalization(
                    type: .subscriptionGroupLocalizations, id: "loc-1",
                    attributes: .init(name: "Premium", customAppName: "Premium App", locale: "en-US")
                ),
                AppStoreConnect_Swift_SDK.SubscriptionGroupLocalization(
                    type: .subscriptionGroupLocalizations, id: "loc-2",
                    attributes: .init(name: "高级", locale: "zh-Hans")
                ),
            ],
            links: .init(this: "")
        ))

        let repo = SDKSubscriptionGroupLocalizationRepository(client: stub)
        let result = try await repo.listLocalizations(groupId: "grp-77")

        #expect(result.count == 2)
        #expect(result.allSatisfy { $0.groupId == "grp-77" })
    }

    @Test func `listLocalizations maps locale, name and customAppName`() async throws {
        let stub = StubAPIClient()
        stub.willReturn(SubscriptionGroupLocalizationsResponse(
            data: [
                AppStoreConnect_Swift_SDK.SubscriptionGroupLocalization(
                    type: .subscriptionGroupLocalizations, id: "loc-1",
                    attributes: .init(name: "Premium", customAppName: "Premium App", locale: "en-US")
                ),
            ],
            links: .init(this: "")
        ))

        let repo = SDKSubscriptionGroupLocalizationRepository(client: stub)
        let result = try await repo.listLocalizations(groupId: "grp-1")

        #expect(result[0].locale == "en-US")
        #expect(result[0].name == "Premium")
        #expect(result[0].customAppName == "Premium App")
    }

    @Test func `createLocalization injects groupId into response`() async throws {
        let stub = StubAPIClient()
        stub.willReturn(SubscriptionGroupLocalizationResponse(
            data: AppStoreConnect_Swift_SDK.SubscriptionGroupLocalization(
                type: .subscriptionGroupLocalizations, id: "loc-new",
                attributes: .init(name: "Premium", locale: "en-US")
            ),
            links: .init(this: "")
        ))

        let repo = SDKSubscriptionGroupLocalizationRepository(client: stub)
        let result = try await repo.createLocalization(
            groupId: "grp-42", locale: "en-US", name: "Premium", customAppName: nil
        )

        #expect(result.id == "loc-new")
        #expect(result.groupId == "grp-42")
        #expect(result.locale == "en-US")
    }

    @Test func `updateLocalization returns updated record with empty groupId`() async throws {
        let stub = StubAPIClient()
        stub.willReturn(SubscriptionGroupLocalizationResponse(
            data: AppStoreConnect_Swift_SDK.SubscriptionGroupLocalization(
                type: .subscriptionGroupLocalizations, id: "loc-1",
                attributes: .init(name: "Renamed", locale: "en-US")
            ),
            links: .init(this: "")
        ))

        let repo = SDKSubscriptionGroupLocalizationRepository(client: stub)
        let result = try await repo.updateLocalization(localizationId: "loc-1", name: "Renamed", customAppName: nil)

        #expect(result.id == "loc-1")
        #expect(result.name == "Renamed")
        // PATCH response does not carry parent id
        #expect(result.groupId == "")
    }

    @Test func `deleteLocalization performs void request`() async throws {
        let stub = StubAPIClient()
        let repo = SDKSubscriptionGroupLocalizationRepository(client: stub)
        try await repo.deleteLocalization(localizationId: "loc-1")
        #expect(stub.voidRequestCalled == true)
    }
}
