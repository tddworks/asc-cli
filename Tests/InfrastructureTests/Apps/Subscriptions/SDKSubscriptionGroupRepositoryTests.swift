@preconcurrency import AppStoreConnect_Swift_SDK
import Testing
@testable import Infrastructure
@testable import Domain

@Suite
struct SDKSubscriptionGroupRepositoryTests {

    // MARK: - listSubscriptionGroups

    @Test func `listSubscriptionGroups injects appId into each group`() async throws {
        let stub = StubAPIClient()
        stub.willReturn(SubscriptionGroupsResponse(
            data: [
                AppStoreConnect_Swift_SDK.SubscriptionGroup(type: .subscriptionGroups, id: "grp-1", attributes: .init(referenceName: "Premium Plans")),
                AppStoreConnect_Swift_SDK.SubscriptionGroup(type: .subscriptionGroups, id: "grp-2", attributes: .init(referenceName: "Pro Plans")),
            ],
            links: .init(this: "")
        ))

        let repo = SDKSubscriptionGroupRepository(client: stub)
        let result = try await repo.listSubscriptionGroups(appId: "app-99", limit: nil)

        #expect(result.data.count == 2)
        #expect(result.data.allSatisfy { $0.appId == "app-99" })
    }

    @Test func `listSubscriptionGroups maps id and referenceName from SDK response`() async throws {
        let stub = StubAPIClient()
        stub.willReturn(SubscriptionGroupsResponse(
            data: [
                AppStoreConnect_Swift_SDK.SubscriptionGroup(type: .subscriptionGroups, id: "grp-abc", attributes: .init(referenceName: "Premium Plans")),
            ],
            links: .init(this: "")
        ))

        let repo = SDKSubscriptionGroupRepository(client: stub)
        let result = try await repo.listSubscriptionGroups(appId: "app-1", limit: nil)

        #expect(result.data[0].id == "grp-abc")
        #expect(result.data[0].referenceName == "Premium Plans")
    }

    // MARK: - createSubscriptionGroup

    @Test func `createSubscriptionGroup injects appId into response`() async throws {
        let stub = StubAPIClient()
        stub.willReturn(SubscriptionGroupResponse(
            data: AppStoreConnect_Swift_SDK.SubscriptionGroup(
                type: .subscriptionGroups,
                id: "grp-new",
                attributes: .init(referenceName: "Premium Plans")
            ),
            links: .init(this: "")
        ))

        let repo = SDKSubscriptionGroupRepository(client: stub)
        let result = try await repo.createSubscriptionGroup(appId: "app-42", referenceName: "Premium Plans")

        #expect(result.id == "grp-new")
        #expect(result.appId == "app-42")
        #expect(result.referenceName == "Premium Plans")
    }
}
