@preconcurrency import AppStoreConnect_Swift_SDK
import Domain

public struct SDKPromotedPurchaseRepository: PromotedPurchaseRepository, @unchecked Sendable {
    private let client: any APIClient

    public init(client: any APIClient) {
        self.client = client
    }

    public func listPromotedPurchases(appId: String, limit: Int?) async throws -> PaginatedResponse<Domain.PromotedPurchase> {
        let request = APIEndpoint.v1.apps.id(appId).promotedPurchases.get(parameters: .init(limit: limit))
        let response = try await client.request(request)
        let purchases = response.data.map { mapPurchase($0, appId: appId) }
        return PaginatedResponse(data: purchases, nextCursor: response.links.next)
    }

    public func createPromotedPurchase(
        appId: String,
        isVisibleForAllUsers: Bool,
        isEnabled: Bool?,
        inAppPurchaseId: String?,
        subscriptionId: String?
    ) async throws -> Domain.PromotedPurchase {
        let iapRel = inAppPurchaseId.map {
            PromotedPurchaseCreateRequest.Data.Relationships.InAppPurchaseV2(data: .init(type: .inAppPurchases, id: $0))
        }
        let subRel = subscriptionId.map {
            PromotedPurchaseCreateRequest.Data.Relationships.Subscription(data: .init(type: .subscriptions, id: $0))
        }
        let body = PromotedPurchaseCreateRequest(data: .init(
            type: .promotedPurchases,
            attributes: .init(isVisibleForAllUsers: isVisibleForAllUsers, isEnabled: isEnabled),
            relationships: .init(
                app: .init(data: .init(type: .apps, id: appId)),
                inAppPurchaseV2: iapRel,
                subscription: subRel
            )
        ))
        let response = try await client.request(APIEndpoint.v1.promotedPurchases.post(body))
        return mapPurchase(response.data, appId: appId)
    }

    public func updatePromotedPurchase(
        promotedId: String,
        isVisibleForAllUsers: Bool?,
        isEnabled: Bool?
    ) async throws -> Domain.PromotedPurchase {
        let body = PromotedPurchaseUpdateRequest(data: .init(
            type: .promotedPurchases,
            id: promotedId,
            attributes: .init(isVisibleForAllUsers: isVisibleForAllUsers, isEnabled: isEnabled)
        ))
        let response = try await client.request(APIEndpoint.v1.promotedPurchases.id(promotedId).patch(body))
        // PATCH does not include parent appId.
        return mapPurchase(response.data, appId: "")
    }

    public func deletePromotedPurchase(promotedId: String) async throws {
        _ = try await client.request(APIEndpoint.v1.promotedPurchases.id(promotedId).delete)
    }

    private func mapPurchase(
        _ sdk: AppStoreConnect_Swift_SDK.PromotedPurchase,
        appId: String
    ) -> Domain.PromotedPurchase {
        let stateRaw = sdk.attributes?.state?.rawValue
        let state = stateRaw.flatMap { Domain.PromotedPurchaseState(rawValue: $0) }
        return Domain.PromotedPurchase(
            id: sdk.id,
            appId: appId,
            isVisibleForAllUsers: sdk.attributes?.isVisibleForAllUsers ?? false,
            isEnabled: sdk.attributes?.isEnabled ?? false,
            state: state,
            inAppPurchaseId: sdk.relationships?.inAppPurchaseV2?.data?.id,
            subscriptionId: sdk.relationships?.subscription?.data?.id
        )
    }
}
