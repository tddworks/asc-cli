@preconcurrency import AppStoreConnect_Swift_SDK
import Domain

public struct SDKInAppPurchaseRepository: InAppPurchaseRepository, @unchecked Sendable {
    private let client: any APIClient
    /// Optional enricher that asks iris for `submitWithNextAppStoreVersion` per IAP
    /// (the public SDK has no path that exposes that bit). Wired by the factory when
    /// iris cookies are available; absent for CI scripts with API-key auth only.
    /// Treated as best-effort — any thrown error inside the closure should map to
    /// an empty dictionary by the wiring layer so the listing call still succeeds.
    private let irisFlagsProvider: (@Sendable (String) async -> [String: Bool])?

    public init(
        client: any APIClient,
        irisFlagsProvider: (@Sendable (String) async -> [String: Bool])? = nil
    ) {
        self.client = client
        self.irisFlagsProvider = irisFlagsProvider
    }

    public func listInAppPurchases(appId: String, limit: Int?) async throws -> PaginatedResponse<Domain.InAppPurchase> {
        let request = APIEndpoint.v1.apps.id(appId).inAppPurchasesV2.get(parameters: .init(
            limit: limit
        ))
        let response = try await client.request(request)
        // First-time detection: if no IAP in this batch has ever been approved by Apple
        // (current state in approved / *removedFromSale*), every unapproved IAP is
        // flagged so the affordance routes through `asc iris iap-submissions create`.
        // The check is per-batch, not authoritative across all IAPs the API might
        // paginate — but `listInAppPurchases` already pulls the full set when `limit`
        // isn't specified, which is the path agents use.
        let hasShippedIAP = response.data.contains { iap in
            let mapped = mapState(iap.attributes?.state)
            return mapped.hasBeenApproved
        }
        let irisFlags = await irisFlagsProvider?(appId) ?? [:]
        let purchases = response.data.map { sdkIAP -> Domain.InAppPurchase in
            let state = mapState(sdkIAP.attributes?.state)
            let isFirstTime = !hasShippedIAP && !state.hasBeenApproved
            let submitWithNextVersion = irisFlags[sdkIAP.id] ?? false
            return mapInAppPurchase(
                sdkIAP, appId: appId,
                isFirstTimeSubmission: isFirstTime,
                submitWithNextAppStoreVersion: submitWithNextVersion
            )
        }
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

    private func mapInAppPurchase(
        _ sdk: AppStoreConnect_Swift_SDK.InAppPurchaseV2,
        appId: String,
        isFirstTimeSubmission: Bool = false,
        submitWithNextAppStoreVersion: Bool = false
    ) -> Domain.InAppPurchase {
        Domain.InAppPurchase(
            id: sdk.id,
            appId: appId,
            referenceName: sdk.attributes?.name ?? "",
            productId: sdk.attributes?.productID ?? "",
            type: mapFromSDKType(sdk.attributes?.inAppPurchaseType) ?? .consumable,
            state: mapState(sdk.attributes?.state),
            reviewNote: sdk.attributes?.reviewNote,
            isFirstTimeSubmission: isFirstTimeSubmission,
            submitWithNextAppStoreVersion: submitWithNextAppStoreVersion
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
