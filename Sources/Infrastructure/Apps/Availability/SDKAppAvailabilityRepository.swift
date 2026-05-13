@preconcurrency import AppStoreConnect_Swift_SDK
import Domain

public struct SDKAppAvailabilityRepository: AppAvailabilityRepository, @unchecked Sendable {
    private let client: any APIClient

    public init(client: any APIClient) {
        self.client = client
    }

    /// Apple caps `include=territoryAvailabilities` on the parent endpoint at 50 entries
    /// (the live error is `PARAMETER_ERROR.INVALID "maximum allowable limit is '50'"`),
    /// and the dedicated relationship endpoint accepts up to 200 per page. So fetch the
    /// availability id from the parent with no `include`, then walk the dedicated
    /// `/v2/appAvailabilities/{id}/territoryAvailabilities` endpoint for the full list.
    ///
    /// The territory code (e.g. `USA`) only appears via the territory relationship —
    /// `TerritoryAvailability.id` itself is an opaque base64 blob — so include the
    /// relationship and read its `data.id`.
    public func getAppAvailability(appId: String) async throws -> Domain.AppAvailability {
        let parentRequest = APIEndpoint.v1.apps.id(appId).appAvailabilityV2.get(parameters: .init(
            fieldsAppAvailabilities: [.availableInNewTerritories]
        ))
        let parent = try await client.request(parentRequest)
        let availabilityId = parent.data.id

        let territoriesRequest = APIEndpoint.v2.appAvailabilities.id(availabilityId).territoryAvailabilities.get(parameters: .init(
            fieldsTerritoryAvailabilities: [.available, .releaseDate, .preOrderEnabled, .preOrderPublishDate, .contentStatuses, .territory],
            limit: 200,
            include: [.territory]
        ))
        let territoriesResponse = try await client.request(territoriesRequest)
        let territories = territoriesResponse.data.compactMap { mapTerritoryAvailability($0) }

        return Domain.AppAvailability(
            id: availabilityId,
            appId: appId,
            isAvailableInNewTerritories: parent.data.attributes?.isAvailableInNewTerritories ?? false,
            territories: territories
        )
    }

    private func mapTerritoryAvailability(
        _ sdk: AppStoreConnect_Swift_SDK.TerritoryAvailability
    ) -> Domain.AppTerritoryAvailability? {
        guard let territoryId = sdk.relationships?.territory?.data?.id else { return nil }
        let contentStatuses = (sdk.attributes?.contentStatuses ?? []).compactMap { sdkStatus in
            Domain.ContentStatus(rawValue: sdkStatus.rawValue)
        }
        return Domain.AppTerritoryAvailability(
            id: sdk.id,
            territoryId: territoryId,
            isAvailable: sdk.attributes?.isAvailable ?? false,
            releaseDate: sdk.attributes?.releaseDate,
            isPreOrderEnabled: sdk.attributes?.isPreOrderEnabled ?? false,
            contentStatuses: contentStatuses
        )
    }
}
