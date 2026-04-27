@preconcurrency import AppStoreConnect_Swift_SDK
import Domain

public struct SDKSubscriptionPriceRepository: SubscriptionPriceRepository, @unchecked Sendable {
    private let client: any APIClient

    public init(client: any APIClient) {
        self.client = client
    }

    public func listPricePoints(
        subscriptionId: String,
        territory: String?,
        limit: Int?,
        cursor: String?
    ) async throws -> Domain.PaginatedResponse<Domain.SubscriptionPricePoint> {
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
        return Domain.PaginatedResponse(
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

    public func setPrices(
        subscriptionId: String,
        prices: [Domain.SubscriptionPriceInput]
    ) async throws -> Domain.SubscriptionPriceSchedule {
        // Apple's API creates one SubscriptionPrice per call. Sequential creates keep
        // semantics simple (no transactional rollback across territories — the developer
        // can re-issue a failed entry).
        for input in prices {
            _ = try await setPrice(
                subscriptionId: subscriptionId,
                territory: input.territory,
                pricePointId: input.pricePointId,
                startDate: input.startDate,
                preserveCurrentPrice: input.preserveCurrentPrice
            )
        }
        // Re-read the schedule so the caller gets the post-write state.
        return try await getPriceSchedule(subscriptionId: subscriptionId)
            ?? Domain.SubscriptionPriceSchedule(id: subscriptionId, subscriptionId: subscriptionId)
    }

    public func listEqualizations(pricePointId: String, limit: Int?) async throws -> [Domain.SubscriptionPricePoint] {
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

    public func getPriceSchedule(subscriptionId: String) async throws -> Domain.SubscriptionPriceSchedule? {
        // Step 1: GET /v1/subscriptions/{id}/prices?include=territory,subscriptionPricePoint
        let pricesResponse = try await client.request(
            APIEndpoint.v1.subscriptions.id(subscriptionId).prices.get(parameters: .init(
                fieldsSubscriptionPrices: [.territory, .subscriptionPricePoint],
                fieldsTerritories: [.currency],
                fieldsSubscriptionPricePoints: [.customerPrice, .proceeds, .proceedsYear2, .territory],
                include: [.territory, .subscriptionPricePoint]
            ))
        )

        // No prices set → no schedule yet.
        guard !pricesResponse.data.isEmpty else { return nil }

        var territoriesById: [String: Domain.Territory] = [:]
        var pricePointsById: [String: AppStoreConnect_Swift_SDK.SubscriptionPricePoint] = [:]
        for item in pricesResponse.included ?? [] {
            switch item {
            case .territory(let t):
                territoriesById[t.id] = Domain.Territory(id: t.id, currency: t.attributes?.currency)
            case .subscriptionPricePoint(let pp):
                pricePointsById[pp.id] = pp
            }
        }

        let manualPrices: [Domain.TerritoryPrice] = pricesResponse.data.compactMap { price in
            guard
                let territoryId = price.relationships?.territory?.data?.id,
                let territory = territoriesById[territoryId],
                let pricePointId = price.relationships?.subscriptionPricePoint?.data?.id,
                let pricePoint = pricePointsById[pricePointId],
                let customerPrice = pricePoint.attributes?.customerPrice,
                let proceeds = pricePoint.attributes?.proceeds
            else { return nil }
            return Domain.TerritoryPrice(territory: territory, customerPrice: customerPrice, proceeds: proceeds)
        }

        // Step 2: equalize using the first manual price's price point.
        let firstPricePointId = pricesResponse.data.first?.relationships?.subscriptionPricePoint?.data?.id
        var equalized: [Domain.TerritoryPrice] = []
        if let pricePointId = firstPricePointId {
            equalized = (try? await fetchEqualizedTerritoryPrices(pricePointId: pricePointId)) ?? []
        }

        // Merge: manual entries override equalized for the same territory.
        var byTerritory: [String: Domain.TerritoryPrice] = [:]
        for entry in equalized   { byTerritory[entry.territory.id] = entry }
        for entry in manualPrices { byTerritory[entry.territory.id] = entry }
        let merged = byTerritory.values.sorted { $0.territory.id < $1.territory.id }

        return Domain.SubscriptionPriceSchedule(
            id: subscriptionId,
            subscriptionId: subscriptionId,
            territoryPrices: merged
        )
    }

    private func fetchEqualizedTerritoryPrices(pricePointId: String) async throws -> [Domain.TerritoryPrice] {
        let response = try await client.request(
            APIEndpoint.v1.subscriptionPricePoints.id(pricePointId).equalizations.get(parameters: .init(
                fieldsSubscriptionPricePoints: [.customerPrice, .proceeds, .proceedsYear2, .territory],
                fieldsTerritories: [.currency],
                limit: 200,
                include: [.territory]
            ))
        )

        var territoriesById: [String: Domain.Territory] = [:]
        for t in response.included ?? [] {
            territoriesById[t.id] = Domain.Territory(id: t.id, currency: t.attributes?.currency)
        }

        return response.data.compactMap { pp in
            guard
                let territoryId = pp.relationships?.territory?.data?.id,
                let customerPrice = pp.attributes?.customerPrice,
                let proceeds = pp.attributes?.proceeds
            else { return nil }
            let territory = territoriesById[territoryId] ?? Domain.Territory(id: territoryId, currency: nil)
            return Domain.TerritoryPrice(territory: territory, customerPrice: customerPrice, proceeds: proceeds)
        }
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
