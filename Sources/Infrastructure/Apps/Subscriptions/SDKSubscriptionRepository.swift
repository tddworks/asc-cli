@preconcurrency import AppStoreConnect_Swift_SDK
import Domain

public struct SDKSubscriptionRepository: SubscriptionRepository, @unchecked Sendable {
    private let client: any APIClient

    public init(client: any APIClient) {
        self.client = client
    }

    public func listSubscriptions(groupId: String, limit: Int?) async throws -> PaginatedResponse<Domain.Subscription> {
        let request = APIEndpoint.v1.subscriptionGroups.id(groupId).subscriptions.get(parameters: .init(
            limit: limit
        ))
        let response = try await client.request(request)
        let subscriptions = response.data.map { mapSubscription($0, groupId: groupId) }
        return PaginatedResponse(data: subscriptions, nextCursor: response.links.next)
    }

    public func createSubscription(
        groupId: String,
        name: String,
        productId: String,
        period: Domain.SubscriptionPeriod,
        isFamilySharable: Bool,
        groupLevel: Int?
    ) async throws -> Domain.Subscription {
        let sdkPeriod = SubscriptionCreateRequest.Data.Attributes.SubscriptionPeriod(rawValue: period.rawValue)
        let body = SubscriptionCreateRequest(data: .init(
            type: .subscriptions,
            attributes: .init(
                name: name,
                productID: productId,
                isFamilySharable: isFamilySharable,
                subscriptionPeriod: sdkPeriod,
                groupLevel: groupLevel
            ),
            relationships: .init(
                group: .init(data: .init(type: .subscriptionGroups, id: groupId))
            )
        ))
        let response = try await client.request(APIEndpoint.v1.subscriptions.post(body))
        return mapSubscription(response.data, groupId: groupId)
    }

    private func mapSubscription(_ sdk: AppStoreConnect_Swift_SDK.Subscription, groupId: String) -> Domain.Subscription {
        let periodRaw = sdk.attributes?.subscriptionPeriod?.rawValue ?? SubscriptionPeriod.oneMonth.rawValue
        let period = Domain.SubscriptionPeriod(rawValue: periodRaw) ?? .oneMonth
        let stateRaw = sdk.attributes?.state?.rawValue ?? SubscriptionState.missingMetadata.rawValue
        let state = Domain.SubscriptionState(rawValue: stateRaw) ?? .missingMetadata
        return Domain.Subscription(
            id: sdk.id,
            groupId: groupId,
            name: sdk.attributes?.name ?? "",
            productId: sdk.attributes?.productID ?? "",
            subscriptionPeriod: period,
            isFamilySharable: sdk.attributes?.isFamilySharable ?? false,
            state: state,
            groupLevel: sdk.attributes?.groupLevel
        )
    }
}
