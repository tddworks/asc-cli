@preconcurrency import AppStoreConnect_Swift_SDK
import Domain

public struct SDKSubscriptionLocalizationRepository: SubscriptionLocalizationRepository, @unchecked Sendable {
    private let client: any APIClient

    public init(client: any APIClient) {
        self.client = client
    }

    public func listLocalizations(subscriptionId: String) async throws -> [Domain.SubscriptionLocalization] {
        let request = APIEndpoint.v1.subscriptions.id(subscriptionId).subscriptionLocalizations.get()
        let response = try await client.request(request)
        return response.data.map { mapLocalization($0, subscriptionId: subscriptionId) }
    }

    public func createLocalization(
        subscriptionId: String,
        locale: String,
        name: String,
        description: String?
    ) async throws -> Domain.SubscriptionLocalization {
        let body = SubscriptionLocalizationCreateRequest(data: .init(
            type: .subscriptionLocalizations,
            attributes: .init(name: name, locale: locale, description: description),
            relationships: .init(
                subscription: .init(data: .init(type: .subscriptions, id: subscriptionId))
            )
        ))
        let response = try await client.request(APIEndpoint.v1.subscriptionLocalizations.post(body))
        return mapLocalization(response.data, subscriptionId: subscriptionId)
    }

    public func updateLocalization(
        localizationId: String,
        name: String?,
        description: String?
    ) async throws -> Domain.SubscriptionLocalization {
        let body = SubscriptionLocalizationUpdateRequest(data: .init(
            type: .subscriptionLocalizations,
            id: localizationId,
            attributes: .init(name: name, description: description)
        ))
        let response = try await client.request(
            APIEndpoint.v1.subscriptionLocalizations.id(localizationId).patch(body)
        )
        return mapLocalization(response.data, subscriptionId: "")
    }

    public func deleteLocalization(localizationId: String) async throws {
        _ = try await client.request(APIEndpoint.v1.subscriptionLocalizations.id(localizationId).delete)
    }

    private func mapLocalization(
        _ sdk: AppStoreConnect_Swift_SDK.SubscriptionLocalization,
        subscriptionId: String
    ) -> Domain.SubscriptionLocalization {
        Domain.SubscriptionLocalization(
            id: sdk.id,
            subscriptionId: subscriptionId,
            locale: sdk.attributes?.locale ?? "",
            name: sdk.attributes?.name,
            description: sdk.attributes?.description,
            state: mapState(sdk.attributes?.state)
        )
    }

    private func mapState(
        _ sdkState: AppStoreConnect_Swift_SDK.SubscriptionLocalization.Attributes.State?
    ) -> Domain.SubscriptionLocalizationState? {
        guard let sdkState else { return nil }
        return Domain.SubscriptionLocalizationState(rawValue: sdkState.rawValue)
    }
}
