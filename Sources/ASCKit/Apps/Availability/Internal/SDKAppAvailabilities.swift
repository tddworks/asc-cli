@preconcurrency import AppStoreConnect_Swift_SDK

public struct SDKAppAvailabilities: AppAvailabilities, @unchecked Sendable {
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
    public func getAppAvailability(appId: String) async throws -> ASCKit.AppAvailability? {
        let parentRequest = APIEndpoint.v1.apps.id(appId).appAvailabilityV2.get(parameters: .init(
            fieldsAppAvailabilities: [.availableInNewTerritories]
        ))
        let parent: AppAvailabilityV2Response
        do {
            parent = try await client.request(parentRequest)
        } catch APIProvider.Error.requestFailure(404, _, _) {
            return nil  // never set up (App Store Connect's "Set Up Availability" state)
        }
        let availabilityId = parent.data.id

        let territoriesRequest = APIEndpoint.v2.appAvailabilities.id(availabilityId).territoryAvailabilities.get(parameters: .init(
            fieldsTerritoryAvailabilities: [.available, .releaseDate, .preOrderEnabled, .preOrderPublishDate, .contentStatuses, .territory],
            limit: 200,
            include: [.territory]
        ))
        let territoriesResponse = try await client.request(territoriesRequest)
        let territories = territoriesResponse.data.compactMap { mapTerritoryAvailability($0) }

        return ASCKit.AppAvailability(
            id: availabilityId,
            appId: appId,
            isAvailableInNewTerritories: parent.data.attributes?.isAvailableInNewTerritories ?? false,
            territories: territories
        )
    }

    public func createAppAvailability(
        appId: String,
        isAvailableInNewTerritories: Bool,
        territoryIds: [String]
    ) async throws -> ASCKit.AppAvailability {
        // Each territory is an inline-created territoryAvailability, correlated by a `${...}` local id.
        let localIds = territoryIds.map { "${ta-\($0)}" }
        let body = AppAvailabilityV2CreateRequest(
            data: .init(
                type: .appAvailabilities,
                attributes: .init(isAvailableInNewTerritories: isAvailableInNewTerritories),
                relationships: .init(
                    app: .init(data: .init(type: .apps, id: appId)),
                    territoryAvailabilities: .init(data: localIds.map { .init(type: .territoryAvailabilities, id: $0) })
                )
            ),
            included: zip(localIds, territoryIds).map { localId, territoryId in
                TerritoryAvailabilityInlineCreate(
                    type: .territoryAvailabilities,
                    id: localId,
                    attributes: .init(isAvailable: true),
                    relationships: .init(territory: .init(data: .init(type: .territories, id: territoryId)))
                )
            }
        )
        _ = try await client.request(APIEndpoint.v2.appAvailabilities.post(body))
        // Read it back for Apple's per-territory statuses.
        guard let created = try await getAppAvailability(appId: appId) else {
            throw APIError.unknown("App availability for \(appId) was created but can't be read back")
        }
        return created
    }

    private func mapTerritoryAvailability(
        _ sdk: AppStoreConnect_Swift_SDK.TerritoryAvailability
    ) -> ASCKit.AppTerritoryAvailability? {
        guard let territoryId = sdk.relationships?.territory?.data?.id else { return nil }
        let contentStatuses = (sdk.attributes?.contentStatuses ?? []).compactMap { sdkStatus in
            ASCKit.ContentStatus(rawValue: sdkStatus.rawValue)
        }
        return ASCKit.AppTerritoryAvailability(
            id: sdk.id,
            territoryId: territoryId,
            isAvailable: sdk.attributes?.isAvailable ?? false,
            releaseDate: sdk.attributes?.releaseDate,
            isPreOrderEnabled: sdk.attributes?.isPreOrderEnabled ?? false,
            contentStatuses: contentStatuses
        )
    }
}
