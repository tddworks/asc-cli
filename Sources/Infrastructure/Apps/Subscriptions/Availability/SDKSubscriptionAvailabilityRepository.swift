@preconcurrency import AppStoreConnect_Swift_SDK
import Domain

public struct SDKSubscriptionAvailabilityRepository: SubscriptionAvailabilityRepository, @unchecked Sendable {
    private let client: any APIClient

    public init(client: any APIClient) {
        self.client = client
    }

    public func getAvailability(subscriptionId: String) async throws -> Domain.SubscriptionAvailability? {
        // Two parallel calls — see SDKInAppPurchaseAvailabilityRepository for rationale.
        // 404 → nil (no availability configured yet on a fresh subscription).
        do {
            async let availResponse = client.request(
                APIEndpoint.v1.subscriptions.id(subscriptionId).subscriptionAvailability.get(parameters: .init())
            )
            async let terrResponse = client.request(
                APIEndpoint.v1.subscriptionAvailabilities.id(subscriptionId).availableTerritories.get(
                    fieldsTerritories: [.currency],
                    limit: 200
                )
            )
            let (avail, terr) = try await (availResponse, terrResponse)

            let territories = terr.data.map { t in
                Domain.Territory(id: t.id, currency: t.attributes?.currency)
            }
            return Domain.SubscriptionAvailability(
                id: avail.data.id,
                subscriptionId: subscriptionId,
                isAvailableInNewTerritories: avail.data.attributes?.isAvailableInNewTerritories ?? false,
                territories: territories
            )
        } catch {
            return nil
        }
    }

    public func createAvailability(
        subscriptionId: String,
        isAvailableInNewTerritories: Bool,
        territoryIds: [String]
    ) async throws -> Domain.SubscriptionAvailability {
        let body = SubscriptionAvailabilityCreateRequest(data: .init(
            type: .subscriptionAvailabilities,
            attributes: .init(isAvailableInNewTerritories: isAvailableInNewTerritories),
            relationships: .init(
                subscription: .init(data: .init(type: .subscriptions, id: subscriptionId)),
                availableTerritories: .init(data: territoryIds.map { .init(type: .territories, id: $0) })
            )
        ))
        let response = try await client.request(APIEndpoint.v1.subscriptionAvailabilities.post(body))
        return mapAvailability(response.data, included: response.included, subscriptionId: subscriptionId)
    }

    private func mapAvailability(
        _ sdk: AppStoreConnect_Swift_SDK.SubscriptionAvailability,
        included: [AppStoreConnect_Swift_SDK.Territory]?,
        subscriptionId: String
    ) -> Domain.SubscriptionAvailability {
        let territoryIds = sdk.relationships?.availableTerritories?.data?.map(\.id) ?? []
        let includedMap = Dictionary(
            uniqueKeysWithValues: (included ?? []).map { ($0.id, $0) }
        )
        let territories = territoryIds.map { id in
            Domain.Territory(id: id, currency: includedMap[id]?.attributes?.currency)
        }
        return Domain.SubscriptionAvailability(
            id: sdk.id,
            subscriptionId: subscriptionId,
            isAvailableInNewTerritories: sdk.attributes?.isAvailableInNewTerritories ?? false,
            territories: territories
        )
    }
}
