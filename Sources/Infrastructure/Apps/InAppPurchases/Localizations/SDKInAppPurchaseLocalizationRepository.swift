@preconcurrency import AppStoreConnect_Swift_SDK
import Domain

public struct SDKInAppPurchaseLocalizationRepository: InAppPurchaseLocalizationRepository, @unchecked Sendable {
    private let client: any APIClient

    public init(client: any APIClient) {
        self.client = client
    }

    public func listLocalizations(iapId: String) async throws -> [Domain.InAppPurchaseLocalization] {
        let request = APIEndpoint.v2.inAppPurchases.id(iapId).inAppPurchaseLocalizations.get()
        let response = try await client.request(request)
        return response.data.map { mapLocalization($0, iapId: iapId) }
    }

    public func createLocalization(
        iapId: String,
        locale: String,
        name: String,
        description: String?
    ) async throws -> Domain.InAppPurchaseLocalization {
        let body = InAppPurchaseLocalizationCreateRequest(data: .init(
            type: .inAppPurchaseLocalizations,
            attributes: .init(name: name, locale: locale, description: description),
            relationships: .init(
                inAppPurchaseV2: .init(data: .init(type: .inAppPurchases, id: iapId))
            )
        ))
        let response = try await client.request(APIEndpoint.v1.inAppPurchaseLocalizations.post(body))
        return mapLocalization(response.data, iapId: iapId)
    }

    public func updateLocalization(
        localizationId: String,
        name: String?,
        description: String?
    ) async throws -> Domain.InAppPurchaseLocalization {
        let body = InAppPurchaseLocalizationUpdateRequest(data: .init(
            type: .inAppPurchaseLocalizations,
            id: localizationId,
            attributes: .init(name: name, description: description)
        ))
        let response = try await client.request(
            APIEndpoint.v1.inAppPurchaseLocalizations.id(localizationId).patch(body)
        )
        // Parent IAP id is not returned on update — preserve from caller intent by leaving empty
        // (callers that need the parent should refetch via listLocalizations)
        return mapLocalization(response.data, iapId: "")
    }

    public func deleteLocalization(localizationId: String) async throws {
        _ = try await client.request(APIEndpoint.v1.inAppPurchaseLocalizations.id(localizationId).delete)
    }

    private func mapLocalization(
        _ sdk: AppStoreConnect_Swift_SDK.InAppPurchaseLocalization,
        iapId: String
    ) -> Domain.InAppPurchaseLocalization {
        Domain.InAppPurchaseLocalization(
            id: sdk.id,
            iapId: iapId,
            locale: sdk.attributes?.locale ?? "",
            name: sdk.attributes?.name,
            description: sdk.attributes?.description,
            state: mapState(sdk.attributes?.state)
        )
    }

    private func mapState(
        _ sdkState: AppStoreConnect_Swift_SDK.InAppPurchaseLocalization.Attributes.State?
    ) -> Domain.InAppPurchaseLocalizationState? {
        guard let sdkState else { return nil }
        return Domain.InAppPurchaseLocalizationState(rawValue: sdkState.rawValue)
    }
}
