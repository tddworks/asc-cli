@preconcurrency import AppStoreConnect_Swift_SDK
import Domain

public struct SDKSubscriptionGroupRepository: SubscriptionGroupRepository, @unchecked Sendable {
    private let client: any APIClient

    public init(client: any APIClient) {
        self.client = client
    }

    public func listSubscriptionGroups(appId: String, limit: Int?) async throws -> PaginatedResponse<Domain.SubscriptionGroup> {
        let request = APIEndpoint.v1.apps.id(appId).subscriptionGroups.get(parameters: .init(
            limit: limit
        ))
        let response = try await client.request(request)
        let groups = response.data.map { mapGroup($0, appId: appId) }
        return PaginatedResponse(data: groups, nextCursor: response.links.next)
    }

    public func createSubscriptionGroup(appId: String, referenceName: String) async throws -> Domain.SubscriptionGroup {
        let body = SubscriptionGroupCreateRequest(data: .init(
            type: .subscriptionGroups,
            attributes: .init(referenceName: referenceName),
            relationships: .init(
                app: .init(data: .init(type: .apps, id: appId))
            )
        ))
        let response = try await client.request(APIEndpoint.v1.subscriptionGroups.post(body))
        return mapGroup(response.data, appId: appId)
    }

    public func updateSubscriptionGroup(
        groupId: String,
        referenceName: String
    ) async throws -> Domain.SubscriptionGroup {
        let body = SubscriptionGroupUpdateRequest(data: .init(
            type: .subscriptionGroups,
            id: groupId,
            attributes: .init(referenceName: referenceName)
        ))
        let response = try await client.request(APIEndpoint.v1.subscriptionGroups.id(groupId).patch(body))
        // PATCH response does not include parent appId — preserve as empty.
        return mapGroup(response.data, appId: "")
    }

    public func deleteSubscriptionGroup(groupId: String) async throws {
        _ = try await client.request(APIEndpoint.v1.subscriptionGroups.id(groupId).delete)
    }

    private func mapGroup(_ sdk: AppStoreConnect_Swift_SDK.SubscriptionGroup, appId: String) -> Domain.SubscriptionGroup {
        Domain.SubscriptionGroup(
            id: sdk.id,
            appId: appId,
            referenceName: sdk.attributes?.referenceName ?? ""
        )
    }
}
