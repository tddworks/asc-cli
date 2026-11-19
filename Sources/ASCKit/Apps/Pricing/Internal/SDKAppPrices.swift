@preconcurrency import AppStoreConnect_Swift_SDK

public struct SDKAppPrices: AppPrices, @unchecked Sendable {
    private let client: any APIClient

    public init(client: any APIClient) {
        self.client = client
    }

    public func hasPricing(appId: String) async throws -> Bool {
        let request = APIEndpoint.v1.apps.id(appId).appPriceSchedule.get()
        do {
            _ = try await client.request(request)
            return true
        } catch {
            return false
        }
    }

    public func listPricePoints(appId: String, territory: String) async throws -> [ASCKit.AppPricePoint] {
        let pages = try await client.requestAllPages(
            APIEndpoint.v1.apps.id(appId).appPricePoints.get(parameters: .init(
                filterTerritory: [territory],
                fieldsAppPricePoints: [.customerPrice, .proceeds],
                limit: 200
            )),
            nextCursor: { $0.meta?.paging.nextCursor }
        )
        // Filtered to one territory, so every point belongs to it.
        return pages.flatMap(\.data).map {
            ASCKit.AppPricePoint(id: $0.id, appId: appId, territory: territory,
                                 customerPrice: $0.attributes?.customerPrice, proceeds: $0.attributes?.proceeds)
        }
    }

    public func setPriceSchedule(appId: String, baseTerritory: String, pricePointId: String) async throws -> ASCKit.AppPriceSchedule {
        // One inline manual price, correlated by a `${...}` local id (same shape as IAP price schedules).
        let localId = "${local-app-price-1}"
        let body = AppPriceScheduleCreateRequest(
            data: .init(
                type: .appPriceSchedules,
                relationships: .init(
                    app: .init(data: .init(type: .apps, id: appId)),
                    baseTerritory: .init(data: .init(type: .territories, id: baseTerritory)),
                    manualPrices: .init(data: [.init(type: .appPrices, id: localId)])
                )
            ),
            included: [
                .appPriceV2InlineCreate(.init(
                    type: .appPrices,
                    id: localId,
                    relationships: .init(appPricePoint: .init(data: .init(type: .appPricePoints, id: pricePointId)))
                )),
            ]
        )
        let response = try await client.request(APIEndpoint.v1.appPriceSchedules.post(body))
        return ASCKit.AppPriceSchedule(id: response.data.id, appId: appId, baseTerritory: baseTerritory)
    }
}
