@preconcurrency import AppStoreConnect_Swift_SDK
import Domain

public struct SDKInAppPurchaseRepository: InAppPurchaseRepository, @unchecked Sendable {
    private let client: any APIClient

    public init(client: any APIClient) {
        self.client = client
    }

    public func listInAppPurchases(appId: String, limit: Int?) async throws -> PaginatedResponse<Domain.InAppPurchase> {
        let request = APIEndpoint.v1.apps.id(appId).inAppPurchasesV2.get(parameters: .init(
            limit: limit
        ))
        let response = try await client.request(request)
        let purchases = response.data.map { mapInAppPurchase($0, appId: appId) }
        return PaginatedResponse(data: purchases, nextCursor: response.links.next)
    }

    public func createInAppPurchase(
        appId: String,
        referenceName: String,
        productId: String,
        type: Domain.InAppPurchaseType
    ) async throws -> Domain.InAppPurchase {
        guard let sdkType = mapToSDKType(type) else {
            throw APIError.unknown("Unsupported IAP type: \(type.rawValue)")
        }
        let body = InAppPurchaseV2CreateRequest(data: .init(
            type: .inAppPurchases,
            attributes: .init(
                name: referenceName,
                productID: productId,
                inAppPurchaseType: sdkType
            ),
            relationships: .init(
                app: .init(data: .init(type: .apps, id: appId))
            )
        ))
        let response = try await client.request(APIEndpoint.v2.inAppPurchases.post(body))
        return mapInAppPurchase(response.data, appId: appId)
    }

    public func updateInAppPurchase(
        iapId: String,
        referenceName: String?,
        reviewNote: String?,
        isFamilySharable: Bool?
    ) async throws -> Domain.InAppPurchase {
        let body = InAppPurchaseV2UpdateRequest(data: .init(
            type: .inAppPurchases,
            id: iapId,
            attributes: .init(
                name: referenceName,
                reviewNote: reviewNote,
                isFamilySharable: isFamilySharable
            )
        ))
        let response = try await client.request(APIEndpoint.v2.inAppPurchases.id(iapId).patch(body))
        // The PATCH response does not include the parent appId — preserve as empty;
        // callers can refetch via listInAppPurchases if they need it.
        return mapInAppPurchase(response.data, appId: "")
    }

    public func deleteInAppPurchase(iapId: String) async throws {
        _ = try await client.request(APIEndpoint.v2.inAppPurchases.id(iapId).delete)
    }

    private func mapInAppPurchase(_ sdk: AppStoreConnect_Swift_SDK.InAppPurchaseV2, appId: String) -> Domain.InAppPurchase {
        Domain.InAppPurchase(
            id: sdk.id,
            appId: appId,
            referenceName: sdk.attributes?.name ?? "",
            productId: sdk.attributes?.productID ?? "",
            type: mapFromSDKType(sdk.attributes?.inAppPurchaseType) ?? .consumable,
            state: mapState(sdk.attributes?.state),
            reviewNote: sdk.attributes?.reviewNote
        )
    }

    private func mapFromSDKType(_ sdkType: AppStoreConnect_Swift_SDK.InAppPurchaseType?) -> Domain.InAppPurchaseType? {
        guard let sdkType else { return nil }
        switch sdkType {
        case .consumable: return .consumable
        case .nonConsumable: return .nonConsumable
        case .nonRenewingSubscription: return .nonRenewingSubscription
        }
    }

    private func mapToSDKType(_ type: Domain.InAppPurchaseType) -> AppStoreConnect_Swift_SDK.InAppPurchaseType? {
        switch type {
        case .consumable: return .consumable
        case .nonConsumable: return .nonConsumable
        case .nonRenewingSubscription: return .nonRenewingSubscription
        case .freeSubscription: return nil
        }
    }

    private func mapState(_ sdkState: AppStoreConnect_Swift_SDK.InAppPurchaseState?) -> Domain.InAppPurchaseState {
        guard let sdkState else { return .missingMetadata }
        return Domain.InAppPurchaseState(rawValue: sdkState.rawValue) ?? .missingMetadata
    }
}
