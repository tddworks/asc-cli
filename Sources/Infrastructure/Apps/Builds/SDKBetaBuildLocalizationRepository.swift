@preconcurrency import AppStoreConnect_Swift_SDK
import Domain

public struct SDKBetaBuildLocalizationRepository: BetaBuildLocalizationRepository, @unchecked Sendable {
    private let client: any APIClient

    public init(client: any APIClient) {
        self.client = client
    }

    public func listBetaBuildLocalizations(buildId: String) async throws -> [Domain.BetaBuildLocalization] {
        let request = APIEndpoint.v1.builds.id(buildId).betaBuildLocalizations.get()
        let response = try await client.request(request)
        return response.data.map { mapLocalization($0, buildId: buildId) }
    }

    public func upsertBetaBuildLocalization(buildId: String, locale: String, whatsNew: String) async throws -> Domain.BetaBuildLocalization {
        // Check for existing localization for this build + locale
        let existing = try await listBetaBuildLocalizations(buildId: buildId)

        if let match = existing.first(where: { $0.locale == locale }) {
            // PATCH existing
            let updateBody = BetaBuildLocalizationUpdateRequest(
                data: .init(
                    type: .betaBuildLocalizations,
                    id: match.id,
                    attributes: .init(whatsNew: whatsNew)
                )
            )
            let response = try await client.request(
                APIEndpoint.v1.betaBuildLocalizations.id(match.id).patch(updateBody)
            )
            return mapLocalization(response.data, buildId: buildId)
        } else {
            // POST new
            let createBody = BetaBuildLocalizationCreateRequest(
                data: .init(
                    type: .betaBuildLocalizations,
                    attributes: .init(whatsNew: whatsNew, locale: locale),
                    relationships: .init(build: .init(data: .init(type: .builds, id: buildId)))
                )
            )
            let response = try await client.request(
                APIEndpoint.v1.betaBuildLocalizations.post(createBody)
            )
            return mapLocalization(response.data, buildId: buildId)
        }
    }

    private func mapLocalization(
        _ sdk: AppStoreConnect_Swift_SDK.BetaBuildLocalization,
        buildId: String
    ) -> Domain.BetaBuildLocalization {
        Domain.BetaBuildLocalization(
            id: sdk.id,
            buildId: buildId,
            locale: sdk.attributes?.locale ?? "",
            whatsNew: sdk.attributes?.whatsNew
        )
    }
}
