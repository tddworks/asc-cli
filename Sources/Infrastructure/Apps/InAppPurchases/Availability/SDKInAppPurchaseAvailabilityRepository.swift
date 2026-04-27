@preconcurrency import AppStoreConnect_Swift_SDK
import Domain

public struct SDKInAppPurchaseAvailabilityRepository: InAppPurchaseAvailabilityRepository, @unchecked Sendable {
    private let client: any APIClient

    public init(client: any APIClient) {
        self.client = client
    }

    public func getAvailability(iapId: String) async throws -> Domain.InAppPurchaseAvailability? {
        // Two parallel calls — `include=availableTerritories` on the parent endpoint truncates
        // the relationship to ~10 entries. Fetching `/availableTerritories?limit=200` returns
        // the full territory list (Apple's max is 175 today).
        //
        // 404 → no availability resource configured yet (typical for newly-created IAPs).
        // Mirrors the iOS SDK's `refreshTerritoryStatuses` 404 tolerance — return nil and let
        // the frontend seed defaults.
        do {
            async let availResponse = client.request(
                APIEndpoint.v2.inAppPurchases.id(iapId).inAppPurchaseAvailability.get(parameters: .init())
            )
            async let terrResponse = client.request(
                APIEndpoint.v1.inAppPurchaseAvailabilities.id(iapId).availableTerritories.get(
                    fieldsTerritories: [.currency],
                    limit: 200
                )
            )
            let (avail, terr) = try await (availResponse, terrResponse)

            let territories = terr.data.map { t in
                Domain.Territory(id: t.id, currency: t.attributes?.currency)
            }
            return Domain.InAppPurchaseAvailability(
                id: avail.data.id,
                iapId: iapId,
                isAvailableInNewTerritories: avail.data.attributes?.isAvailableInNewTerritories ?? false,
                territories: territories
            )
        } catch {
            return nil
        }
    }

    public func createAvailability(
        iapId: String,
        isAvailableInNewTerritories: Bool,
        territoryIds: [String]
    ) async throws -> Domain.InAppPurchaseAvailability {
        let body = InAppPurchaseAvailabilityCreateRequest(data: .init(
            type: .inAppPurchaseAvailabilities,
            attributes: .init(isAvailableInNewTerritories: isAvailableInNewTerritories),
            relationships: .init(
                inAppPurchase: .init(data: .init(type: .inAppPurchases, id: iapId)),
                availableTerritories: .init(data: territoryIds.map { .init(type: .territories, id: $0) })
            )
        ))
        let response = try await client.request(APIEndpoint.v1.inAppPurchaseAvailabilities.post(body))
        return mapAvailability(response.data, included: response.included, iapId: iapId)
    }

    private func mapAvailability(
        _ sdk: AppStoreConnect_Swift_SDK.InAppPurchaseAvailability,
        included: [AppStoreConnect_Swift_SDK.Territory]?,
        iapId: String
    ) -> Domain.InAppPurchaseAvailability {
        let territoryIds = sdk.relationships?.availableTerritories?.data?.map(\.id) ?? []
        let includedMap = Dictionary(
            uniqueKeysWithValues: (included ?? []).map { ($0.id, $0) }
        )
        let territories = territoryIds.map { id in
            Domain.Territory(id: id, currency: includedMap[id]?.attributes?.currency)
        }
        return Domain.InAppPurchaseAvailability(
            id: sdk.id,
            iapId: iapId,
            isAvailableInNewTerritories: sdk.attributes?.isAvailableInNewTerritories ?? false,
            territories: territories
        )
    }
}
