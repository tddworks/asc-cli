@preconcurrency import AppStoreConnect_Swift_SDK
import Domain

public struct SDKInAppPurchasePriceRepository: InAppPurchasePriceRepository, @unchecked Sendable {
    private let client: any APIClient

    public init(client: any APIClient) {
        self.client = client
    }

    public func getPriceSchedule(iapId: String) async throws -> Domain.InAppPurchasePriceSchedule? {
        do {
            let response = try await client.request(
                APIEndpoint.v2.inAppPurchases.id(iapId).iapPriceSchedule.get()
            )
            return Domain.InAppPurchasePriceSchedule(id: response.data.id, iapId: iapId)
        } catch {
            // 404 → no schedule configured yet
            return nil
        }
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
