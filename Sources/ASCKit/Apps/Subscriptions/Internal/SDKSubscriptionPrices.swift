@preconcurrency import AppStoreConnect_Swift_SDK

public struct SDKSubscriptionPrices: SubscriptionPrices, @unchecked Sendable {
    private let client: any APIClient

    public init(client: any APIClient) {
        self.client = client
    }

    public func listPricePoints(
        subscriptionId: String,
        territory: String?,
        limit: Int?,
        cursor: String?
    ) async throws -> ASCKit.PaginatedResponse<ASCKit.SubscriptionPricePoint> {
        var request = APIEndpoint.v1.subscriptions.id(subscriptionId).pricePoints.get(
            parameters: .init(
                filterTerritory: territory.map { [$0] },
                fieldsSubscriptionPricePoints: [.customerPrice, .proceeds, .proceedsYear2, .territory],
                limit: limit
            )
        )
        if let cursor {
            var query = request.query ?? []
            query.append(("cursor", cursor))
            request.query = query
        }
        let response = try await client.request(request)
        return ASCKit.PaginatedResponse(
            data: response.data.map { mapPricePoint($0, subscriptionId: subscriptionId) },
            nextCursor: response.meta?.paging.nextCursor,
            totalCount: response.meta?.paging.total
        )
    }

    public func setPrice(
        subscriptionId: String,
        territory: String,
        pricePointId: String,
        startDate: String?,
        preserveCurrentPrice: Bool?
    ) async throws -> ASCKit.SubscriptionPrice {
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
        return ASCKit.SubscriptionPrice(id: response.data.id, subscriptionId: subscriptionId)
    }

    public func setPrices(
        subscriptionId: String,
        prices: [ASCKit.SubscriptionPriceInput]
    ) async throws -> ASCKit.SubscriptionPriceSchedule {
        // One PATCH with every price inlined — a single request instead of one POST per
        // territory, and Apple applies it all-or-nothing.
        let localIds = prices.indices.map { "${price-\($0)}" }
        let body = SubscriptionUpdateRequest(
            data: .init(
                type: .subscriptions,
                id: subscriptionId,
                relationships: .init(prices: .init(data: localIds.map { .init(type: .subscriptionPrices, id: $0) }))
            ),
            included: zip(localIds, prices).map { localId, input in
                .subscriptionPriceInlineCreate(SubscriptionPriceInlineCreate(
                    type: .subscriptionPrices,
                    id: localId,
                    attributes: .init(startDate: input.startDate, isPreserveCurrentPrice: input.preserveCurrentPrice),
                    relationships: .init(
                        territory: .init(data: .init(type: .territories, id: input.territory)),
                        subscriptionPricePoint: .init(data: .init(type: .subscriptionPricePoints, id: input.pricePointId))
                    )
                ))
            }
        )
        _ = try await client.request(APIEndpoint.v1.subscriptions.id(subscriptionId).patch(body))
        // Re-read the schedule so the caller gets the post-write state.
        return try await getPriceSchedule(subscriptionId: subscriptionId)
            ?? ASCKit.SubscriptionPriceSchedule(id: subscriptionId, subscriptionId: subscriptionId)
    }

    public func listEqualizations(pricePointId: String, limit: Int?) async throws -> [ASCKit.SubscriptionPricePoint] {
        let request = APIEndpoint.v1.subscriptionPricePoints.id(pricePointId).equalizations.get(
            parameters: .init(
                fieldsSubscriptionPricePoints: [.customerPrice, .proceeds, .proceedsYear2, .territory],
                fieldsTerritories: [.currency],
                limit: limit,
                include: [.territory]
            )
        )
        let response = try await client.request(request)
        // The equalizations endpoint is keyed by price point — `subscriptionId` isn't in the
        // response, so callers receive an empty string.
        return response.data.map { mapPricePoint($0, subscriptionId: "") }
    }

    public func getPriceSchedule(subscriptionId: String) async throws -> ASCKit.SubscriptionPriceSchedule? {
        // Step 1: GET /v1/subscriptions/{id}/prices?include=territory,subscriptionPricePoint,
        // following every page — a subscription can have a manual price in all 175 territories.
        let pages = try await client.requestAllPages(
            APIEndpoint.v1.subscriptions.id(subscriptionId).prices.get(parameters: .init(
                fieldsSubscriptionPrices: [.territory, .subscriptionPricePoint],
                fieldsTerritories: [.currency],
                fieldsSubscriptionPricePoints: [.customerPrice, .proceeds, .proceedsYear2, .territory],
                limit: 200,
                include: [.territory, .subscriptionPricePoint]
            )),
            nextCursor: { $0.meta?.paging.nextCursor }
        )
        let pricesData = pages.flatMap(\.data)
        let pricesIncluded = pages.flatMap { $0.included ?? [] }

        // No prices set → no schedule yet.
        guard !pricesData.isEmpty else { return nil }

        var territoriesById: [String: ASCKit.Territory] = [:]
        var pricePointsById: [String: AppStoreConnect_Swift_SDK.SubscriptionPricePoint] = [:]
        for item in pricesIncluded {
            switch item {
            case .territory(let t):
                territoriesById[t.id] = ASCKit.Territory(id: t.id, currency: t.attributes?.currency)
            case .subscriptionPricePoint(let pp):
                pricePointsById[pp.id] = pp
            }
        }

        let manualPrices: [ASCKit.TerritoryPrice] = pricesData.compactMap { price in
            guard
                let territoryId = price.relationships?.territory?.data?.id,
                let territory = territoriesById[territoryId],
                let pricePointId = price.relationships?.subscriptionPricePoint?.data?.id,
                let pricePoint = pricePointsById[pricePointId],
                let customerPrice = pricePoint.attributes?.customerPrice,
                let proceeds = pricePoint.attributes?.proceeds
            else { return nil }
            return ASCKit.TerritoryPrice(territory: territory, customerPrice: customerPrice, proceeds: proceeds)
        }

        // Step 2: equalize using the first manual price's price point.
        let firstPricePointId = pricesData.first?.relationships?.subscriptionPricePoint?.data?.id
        var equalized: [ASCKit.TerritoryPrice] = []
        if let pricePointId = firstPricePointId {
            equalized = (try? await fetchEqualizedTerritoryPrices(pricePointId: pricePointId)) ?? []
        }

        // Merge: manual entries override equalized for the same territory.
        var byTerritory: [String: ASCKit.TerritoryPrice] = [:]
        for entry in equalized   { byTerritory[entry.territory.id] = entry }
        for entry in manualPrices { byTerritory[entry.territory.id] = entry }
        let merged = byTerritory.values.sorted { $0.territory.id < $1.territory.id }

        return ASCKit.SubscriptionPriceSchedule(
            id: subscriptionId,
            subscriptionId: subscriptionId,
            territoryPrices: merged
        )
    }

    private func fetchEqualizedTerritoryPrices(pricePointId: String) async throws -> [ASCKit.TerritoryPrice] {
        let response = try await client.request(
            APIEndpoint.v1.subscriptionPricePoints.id(pricePointId).equalizations.get(parameters: .init(
                fieldsSubscriptionPricePoints: [.customerPrice, .proceeds, .proceedsYear2, .territory],
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

    private func mapPricePoint(
        _ sdk: AppStoreConnect_Swift_SDK.SubscriptionPricePoint,
        subscriptionId: String
    ) -> ASCKit.SubscriptionPricePoint {
        ASCKit.SubscriptionPricePoint(
            id: sdk.id,
            subscriptionId: subscriptionId,
            territory: sdk.relationships?.territory?.data?.id,
            customerPrice: sdk.attributes?.customerPrice,
            proceeds: sdk.attributes?.proceeds,
            proceedsYear2: sdk.attributes?.proceedsYear2
        )
    }
}
