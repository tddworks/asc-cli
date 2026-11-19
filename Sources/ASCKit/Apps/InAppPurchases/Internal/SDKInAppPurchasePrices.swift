@preconcurrency import AppStoreConnect_Swift_SDK

public struct SDKInAppPurchasePrices: InAppPurchasePrices, @unchecked Sendable {
    private let client: any APIClient

    public init(client: any APIClient) {
        self.client = client
    }

    public func getPriceSchedule(iapId: String) async throws -> ASCKit.InAppPurchasePriceSchedule? {
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
        // Follow every page — manual prices can cover all 175 territories.
        let manualPages = try await client.requestAllPages(
            APIEndpoint.v1.inAppPurchasePriceSchedules.id(scheduleId).manualPrices.get(parameters: .init(
                fieldsInAppPurchasePrices: [.inAppPurchasePricePoint, .territory],
                fieldsInAppPurchasePricePoints: [.customerPrice, .proceeds, .territory],
                fieldsTerritories: [.currency],
                limit: 200,
                include: [.inAppPurchasePricePoint, .territory]
            )),
            nextCursor: { $0.meta?.paging.nextCursor }
        )
        let manualData = manualPages.flatMap(\.data)

        // Index included territories + price points for lookup.
        var territoriesById: [String: ASCKit.Territory] = [:]
        var pricePointsById: [String: AppStoreConnect_Swift_SDK.InAppPurchasePricePoint] = [:]
        for item in manualPages.flatMap({ $0.included ?? [] }) {
            switch item {
            case .territory(let t):
                territoriesById[t.id] = ASCKit.Territory(id: t.id, currency: t.attributes?.currency)
            case .inAppPurchasePricePoint(let pp):
                pricePointsById[pp.id] = pp
            }
        }

        let manualPrices: [ASCKit.TerritoryPrice] = manualData.compactMap { price in
            guard
                let territoryId = price.relationships?.territory?.data?.id,
                let territory = territoriesById[territoryId],
                let pricePointId = price.relationships?.inAppPurchasePricePoint?.data?.id,
                let pricePoint = pricePointsById[pricePointId],
                let customerPrice = pricePoint.attributes?.customerPrice,
                let proceeds = pricePoint.attributes?.proceeds
            else { return nil }
            return ASCKit.TerritoryPrice(territory: territory, customerPrice: customerPrice, proceeds: proceeds)
        }

        // Step 3: equalizations — fetch the full ~175-territory list using the manual price's
        // price point. If there are no manual prices we have nothing to equalize from.
        let manualPricePointId = manualData.first?.relationships?.inAppPurchasePricePoint?.data?.id
        var equalizedPrices: [ASCKit.TerritoryPrice] = []
        if let pricePointId = manualPricePointId {
            equalizedPrices = (try? await fetchEqualizedTerritoryPrices(pricePointId: pricePointId)) ?? []
        }

        // Merge: manual entries override equalized entries for the same territory.
        var byTerritory: [String: ASCKit.TerritoryPrice] = [:]
        for entry in equalizedPrices { byTerritory[entry.territory.id] = entry }
        for entry in manualPrices    { byTerritory[entry.territory.id] = entry }
        let merged = byTerritory.values.sorted { $0.territory.id < $1.territory.id }

        return ASCKit.InAppPurchasePriceSchedule(
            id: scheduleId,
            iapId: iapId,
            baseTerritory: baseTerritory,
            territoryPrices: merged
        )
    }

    private func fetchEqualizedTerritoryPrices(pricePointId: String) async throws -> [ASCKit.TerritoryPrice] {
        let response = try await client.request(
            APIEndpoint.v1.inAppPurchasePricePoints.id(pricePointId).equalizations.get(parameters: .init(
                fieldsInAppPurchasePricePoints: [.customerPrice, .proceeds, .territory],
                fieldsTerritories: [.currency],
                limit: 200,
                include: [.territory]
            ))
        )

        var territoriesById: [String: ASCKit.Territory] = [:]
        for t in response.included ?? [] {
            territoriesById[t.id] = ASCKit.Territory(id: t.id, currency: t.attributes?.currency)
        }

        return response.data.compactMap { pp in
            guard
                let territoryId = pp.relationships?.territory?.data?.id,
                let customerPrice = pp.attributes?.customerPrice,
                let proceeds = pp.attributes?.proceeds
            else { return nil }
            let territory = territoriesById[territoryId] ?? ASCKit.Territory(id: territoryId, currency: nil)
            return ASCKit.TerritoryPrice(territory: territory, customerPrice: customerPrice, proceeds: proceeds)
        }
    }

    public func listEqualizations(pricePointId: String, limit: Int?) async throws -> [ASCKit.InAppPurchasePricePoint] {
        let request = APIEndpoint.v1.inAppPurchasePricePoints.id(pricePointId).equalizations.get(
            parameters: .init(
                fieldsInAppPurchasePricePoints: [.customerPrice, .proceeds, .territory],
                fieldsTerritories: [.currency],
                limit: limit,
                include: [.territory]
            )
        )
        let response = try await client.request(request)
        // The equalizations endpoint is keyed by price point — the IAP id isn't in the
        // response, so callers receive an empty `iapId`. Domain consumers usually re-inject.
        return response.data.map { mapPricePoint($0, iapId: "") }
    }

    private func extractTerritory(
        id: String,
        included: [AppStoreConnect_Swift_SDK.InAppPurchasePriceScheduleResponse.IncludedItem]?
    ) -> ASCKit.Territory? {
        for item in included ?? [] {
            if case let .territory(t) = item, t.id == id {
                return ASCKit.Territory(id: t.id, currency: t.attributes?.currency)
            }
        }
        // Fall back to id-only territory if the include didn't return it.
        return ASCKit.Territory(id: id, currency: nil)
    }

    public func listPricePoints(
        iapId: String,
        territory: String?,
        limit: Int?,
        cursor: String?
    ) async throws -> ASCKit.PaginatedResponse<ASCKit.InAppPurchasePricePoint> {
        var request = APIEndpoint.v2.inAppPurchases.id(iapId).pricePoints.get(
            parameters: .init(
                filterTerritory: territory.map { [$0] },
                fieldsInAppPurchasePricePoints: [.customerPrice, .proceeds, .territory],
                limit: limit
            )
        )
        // The generated SDK doesn't expose `cursor` on `GetParameters` — append it manually.
        if let cursor {
            var query = request.query ?? []
            query.append(("cursor", cursor))
            request.query = query
        }
        let response = try await client.request(request)
        return ASCKit.PaginatedResponse(
            data: response.data.map { mapPricePoint($0, iapId: iapId) },
            nextCursor: response.meta?.paging.nextCursor,
            totalCount: response.meta?.paging.total
        )
    }

    public func setPriceSchedule(iapId: String, baseTerritory: String, pricePointId: String) async throws -> ASCKit.InAppPurchasePriceSchedule {
        let body = Self.makePriceScheduleCreateRequest(
            iapId: iapId,
            baseTerritory: baseTerritory,
            pricePointId: pricePointId
        )
        let response = try await client.request(APIEndpoint.v1.inAppPurchasePriceSchedules.post(body))
        return ASCKit.InAppPurchasePriceSchedule(id: response.data.id, iapId: iapId)
    }

    /// Mirrors the iOS app's price-schedule POST shape. ASC requires the inline manual price
    /// to use the `${...}` placeholder so the relationship correlation works, and to carry an
    /// `inAppPurchaseV2` back-reference. Without both, ASC rejects the create with a 4xx.
    static func makePriceScheduleCreateRequest(
        iapId: String,
        baseTerritory: String,
        pricePointId: String
    ) -> InAppPurchasePriceScheduleCreateRequest {
        let tempId = "${local-manual-price-1}"
        return InAppPurchasePriceScheduleCreateRequest(
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
                        inAppPurchaseV2: .init(data: .init(type: .inAppPurchases, id: iapId)),
                        inAppPurchasePricePoint: .init(data: .init(type: .inAppPurchasePricePoints, id: pricePointId))
                    )
                ))
            ]
        )
    }

    private func mapPricePoint(_ sdk: AppStoreConnect_Swift_SDK.InAppPurchasePricePoint, iapId: String) -> ASCKit.InAppPurchasePricePoint {
        ASCKit.InAppPurchasePricePoint(
            id: sdk.id,
            iapId: iapId,
            territory: sdk.relationships?.territory?.data?.id,
            customerPrice: sdk.attributes?.customerPrice,
            proceeds: sdk.attributes?.proceeds
        )
    }
}
