@preconcurrency import AppStoreConnect_Swift_SDK
import Domain

public struct SDKInAppPurchasePriceRepository: InAppPurchasePriceRepository, @unchecked Sendable {
    private let client: any APIClient

    public init(client: any APIClient) {
        self.client = client
    }

    public func getPriceSchedule(iapId: String) async throws -> Domain.InAppPurchasePriceSchedule? {
        // Step 1: schedule + base territory.
        let schedule: AppStoreConnect_Swift_SDK.InAppPurchasePriceScheduleResponse
        do {
            schedule = try await client.request(
                APIEndpoint.v2.inAppPurchases.id(iapId).iapPriceSchedule.get(parameters: .init(
                    fieldsTerritories: [.currency],
                    include: [.baseTerritory]
                ))
            )
        } catch {
            // 404 → no schedule configured yet
            return nil
        }

        let scheduleId = schedule.data.id
        let baseTerritoryId = schedule.data.relationships?.baseTerritory?.data?.id
        let baseTerritory = baseTerritoryId.flatMap { id in
            extractTerritory(id: id, included: schedule.included)
        }

        // Step 2: manual prices with territory + price point includes.
        let manualResponse = try await client.request(
            APIEndpoint.v1.inAppPurchasePriceSchedules.id(scheduleId).manualPrices.get(parameters: .init(
                fieldsInAppPurchasePrices: [.inAppPurchasePricePoint, .territory],
                fieldsInAppPurchasePricePoints: [.customerPrice, .proceeds, .territory],
                fieldsTerritories: [.currency],
                include: [.inAppPurchasePricePoint, .territory]
            ))
        )

        // Index included territories + price points for lookup.
        var territoriesById: [String: Domain.Territory] = [:]
        var pricePointsById: [String: AppStoreConnect_Swift_SDK.InAppPurchasePricePoint] = [:]
        for item in manualResponse.included ?? [] {
            switch item {
            case .territory(let t):
                territoriesById[t.id] = Domain.Territory(id: t.id, currency: t.attributes?.currency)
            case .inAppPurchasePricePoint(let pp):
                pricePointsById[pp.id] = pp
            }
        }

        let territoryPrices: [Domain.TerritoryPrice] = manualResponse.data.compactMap { price in
            guard
                let territoryId = price.relationships?.territory?.data?.id,
                let territory = territoriesById[territoryId],
                let pricePointId = price.relationships?.inAppPurchasePricePoint?.data?.id,
                let pricePoint = pricePointsById[pricePointId],
                let customerPrice = pricePoint.attributes?.customerPrice,
                let proceeds = pricePoint.attributes?.proceeds
            else { return nil }
            return Domain.TerritoryPrice(territory: territory, customerPrice: customerPrice, proceeds: proceeds)
        }

        return Domain.InAppPurchasePriceSchedule(
            id: scheduleId,
            iapId: iapId,
            baseTerritory: baseTerritory,
            territoryPrices: territoryPrices
        )
    }

    private func extractTerritory(
        id: String,
        included: [AppStoreConnect_Swift_SDK.InAppPurchasePriceScheduleResponse.IncludedItem]?
    ) -> Domain.Territory? {
        for item in included ?? [] {
            if case let .territory(t) = item, t.id == id {
                return Domain.Territory(id: t.id, currency: t.attributes?.currency)
            }
        }
        // Fall back to id-only territory if the include didn't return it.
        return Domain.Territory(id: id, currency: nil)
    }

    public func listPricePoints(iapId: String, territory: String?) async throws -> [Domain.InAppPurchasePricePoint] {
        let request = APIEndpoint.v2.inAppPurchases.id(iapId).pricePoints.get(
            parameters: .init(
                filterTerritory: territory.map { [$0] },
                fieldsInAppPurchasePricePoints: [.customerPrice, .proceeds, .territory]
            )
        )
        let response = try await client.request(request)
        return response.data.map { mapPricePoint($0, iapId: iapId) }
    }

    public func setPriceSchedule(iapId: String, baseTerritory: String, pricePointId: String) async throws -> Domain.InAppPurchasePriceSchedule {
        let tempId = "p1"
        let body = InAppPurchasePriceScheduleCreateRequest(
            data: .init(
                type: .inAppPurchasePriceSchedules,
                relationships: .init(
                    inAppPurchase: .init(data: .init(type: .inAppPurchases, id: iapId)),
                    baseTerritory: .init(data: .init(type: .territories, id: baseTerritory)),
                    manualPrices: .init(data: [.init(type: .inAppPurchasePrices, id: tempId)])
                )
            ),
            included: [
                .inAppPurchasePriceInlineCreate(.init(
                    type: .inAppPurchasePrices,
                    id: tempId,
                    relationships: .init(
                        inAppPurchasePricePoint: .init(data: .init(type: .inAppPurchasePricePoints, id: pricePointId))
                    )
                ))
            ]
        )
        let response = try await client.request(APIEndpoint.v1.inAppPurchasePriceSchedules.post(body))
        return Domain.InAppPurchasePriceSchedule(id: response.data.id, iapId: iapId)
    }

    private func mapPricePoint(_ sdk: AppStoreConnect_Swift_SDK.InAppPurchasePricePoint, iapId: String) -> Domain.InAppPurchasePricePoint {
        Domain.InAppPurchasePricePoint(
            id: sdk.id,
            iapId: iapId,
            territory: sdk.relationships?.territory?.data?.id,
            customerPrice: sdk.attributes?.customerPrice,
            proceeds: sdk.attributes?.proceeds
        )
    }
}
