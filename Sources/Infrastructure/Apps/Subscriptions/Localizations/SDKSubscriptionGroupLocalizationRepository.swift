@preconcurrency import AppStoreConnect_Swift_SDK
import Domain

public struct SDKSubscriptionGroupLocalizationRepository: SubscriptionGroupLocalizationRepository, @unchecked Sendable {
    private let client: any APIClient

    public init(client: any APIClient) {
        self.client = client
    }

    public func listLocalizations(groupId: String) async throws -> [Domain.SubscriptionGroupLocalization] {
        let request = APIEndpoint.v1.subscriptionGroups.id(groupId).subscriptionGroupLocalizations.get()
        let response = try await client.request(request)
        return response.data.map { mapLocalization($0, groupId: groupId) }
    }

    public func createLocalization(
        groupId: String,
        locale: String,
        name: String,
        customAppName: String?
    ) async throws -> Domain.SubscriptionGroupLocalization {
        let body = SubscriptionGroupLocalizationCreateRequest(data: .init(
            type: .subscriptionGroupLocalizations,
            attributes: .init(name: name, customAppName: customAppName, locale: locale),
            relationships: .init(
                subscriptionGroup: .init(data: .init(type: .subscriptionGroups, id: groupId))
            )
        ))
        let response = try await client.request(APIEndpoint.v1.subscriptionGroupLocalizations.post(body))
        return mapLocalization(response.data, groupId: groupId)
    }

    public func updateLocalization(
        localizationId: String,
        name: String?,
        customAppName: String?
    ) async throws -> Domain.SubscriptionGroupLocalization {
        let body = SubscriptionGroupLocalizationUpdateRequest(data: .init(
            type: .subscriptionGroupLocalizations,
            id: localizationId,
            attributes: .init(name: name, customAppName: customAppName)
        ))
        let response = try await client.request(APIEndpoint.v1.subscriptionGroupLocalizations.id(localizationId).patch(body))
        return mapLocalization(response.data, groupId: "")
    }

    public func deleteLocalization(localizationId: String) async throws {
        _ = try await client.request(APIEndpoint.v1.subscriptionGroupLocalizations.id(localizationId).delete)
    }

    private func mapLocalization(
        _ sdk: AppStoreConnect_Swift_SDK.SubscriptionGroupLocalization,
        groupId: String
    ) -> Domain.SubscriptionGroupLocalization {
        Domain.SubscriptionGroupLocalization(
            id: sdk.id,
            groupId: groupId,
            locale: sdk.attributes?.locale ?? "",
            name: sdk.attributes?.name,
            customAppName: sdk.attributes?.customAppName,
            state: mapState(sdk.attributes?.state)
        )
    }

    private func mapState(
        _ sdkState: AppStoreConnect_Swift_SDK.SubscriptionGroupLocalization.Attributes.State?
    ) -> Domain.SubscriptionGroupLocalizationState? {
        guard let sdkState else { return nil }
        return Domain.SubscriptionGroupLocalizationState(rawValue: sdkState.rawValue)
    }
}
