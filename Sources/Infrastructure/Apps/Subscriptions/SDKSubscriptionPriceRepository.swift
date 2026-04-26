@preconcurrency import AppStoreConnect_Swift_SDK
import Domain

public struct SDKSubscriptionPriceRepository: SubscriptionPriceRepository, @unchecked Sendable {
    private let client: any APIClient

    public init(client: any APIClient) {
        self.client = client
    }

    public func listPricePoints(subscriptionId: String, territory: String?) async throws -> [Domain.SubscriptionPricePoint] {
        let request = APIEndpoint.v1.subscriptions.id(subscriptionId).pricePoints.get(
            parameters: .init(
                filterTerritory: territory.map { [$0] },
                fieldsSubscriptionPricePoints: [.customerPrice, .proceeds, .proceedsYear2, .territory]
            )
        )
        let response = try await client.request(request)
        return response.data.map { mapPricePoint($0, subscriptionId: subscriptionId) }
    }

    public func setPrice(
        subscriptionId: String,
        territory: String,
        pricePointId: String,
        startDate: String?,
        preserveCurrentPrice: Bool?
    ) async throws -> Domain.SubscriptionPrice {
        let body = SubscriptionPriceCreateRequest(data: .init(
            type: .subscriptionPrices,
            attributes: .init(startDate: startDate, isPreserveCurrentPrice: preserveCurrentPrice),
            relationships: .init(
                subscription: .init(data: .init(type: .subscriptions, id: subscriptionId)),
                territory: .init(data: .init(type: .territories, id: territory)),
                subscriptionPricePoint: .init(data: .init(type: .subscriptionPricePoints, id: pricePointId))
            )
        ))
        let response = try await client.request(APIEndpoint.v1.subscriptionPrices.post(body))
        return Domain.SubscriptionPrice(id: response.data.id, subscriptionId: subscriptionId)
    }

    private func mapPricePoint(
        _ sdk: AppStoreConnect_Swift_SDK.SubscriptionPricePoint,
        subscriptionId: String
    ) -> Domain.SubscriptionPricePoint {
        Domain.SubscriptionPricePoint(
            id: sdk.id,
            subscriptionId: subscriptionId,
            territory: sdk.relationships?.territory?.data?.id,
            customerPrice: sdk.attributes?.customerPrice,
            proceeds: sdk.attributes?.proceeds,
            proceedsYear2: sdk.attributes?.proceedsYear2
        )
    }
}
