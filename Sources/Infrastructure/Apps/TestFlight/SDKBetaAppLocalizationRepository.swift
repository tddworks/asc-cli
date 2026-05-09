@preconcurrency import AppStoreConnect_Swift_SDK
import Domain

public struct SDKBetaAppLocalizationRepository: BetaAppLocalizationRepository, @unchecked Sendable {
    private let client: any APIClient

    public init(client: any APIClient) {
        self.client = client
    }

    public func listBetaAppLocalizations(appId: String) async throws -> [Domain.BetaAppLocalization] {
        let response = try await client.request(
            APIEndpoint.v1.apps.id(appId).betaAppLocalizations.get()
        )
        return response.data.map { map($0, fallbackAppId: appId) }
    }

    public func getBetaAppLocalization(localizationId: String) async throws -> Domain.BetaAppLocalization {
        let response = try await client.request(
            APIEndpoint.v1.betaAppLocalizations.id(localizationId).get()
        )
        return map(response.data, fallbackAppId: "")
    }

    public func createBetaAppLocalization(
        appId: String,
        locale: String,
        update: Domain.BetaAppLocalizationUpdate
    ) async throws -> Domain.BetaAppLocalization {
        let body = BetaAppLocalizationCreateRequest(
            data: .init(
                type: .betaAppLocalizations,
                attributes: .init(
                    feedbackEmail: update.feedbackEmail,
                    marketingURL: update.marketingUrl,
                    privacyPolicyURL: update.privacyPolicyUrl,
                    tvOsPrivacyPolicy: update.tvOsPrivacyPolicy,
                    description: update.description,
                    locale: locale
                ),
                relationships: .init(
                    app: .init(data: .init(type: .apps, id: appId))
                )
            )
        )
        let response = try await client.request(
            APIEndpoint.v1.betaAppLocalizations.post(body)
        )
        return map(response.data, fallbackAppId: appId)
    }

    public func updateBetaAppLocalization(
        localizationId: String,
        update: Domain.BetaAppLocalizationUpdate
    ) async throws -> Domain.BetaAppLocalization {
        let body = BetaAppLocalizationUpdateRequest(
            data: .init(
                type: .betaAppLocalizations,
                id: localizationId,
                attributes: .init(
                    feedbackEmail: update.feedbackEmail,
                    marketingURL: update.marketingUrl,
                    privacyPolicyURL: update.privacyPolicyUrl,
                    tvOsPrivacyPolicy: update.tvOsPrivacyPolicy,
                    description: update.description
                )
            )
        )
        let response = try await client.request(
            APIEndpoint.v1.betaAppLocalizations.id(localizationId).patch(body)
        )
        return map(response.data, fallbackAppId: "")
    }

    public func deleteBetaAppLocalization(localizationId: String) async throws {
        try await client.request(
            APIEndpoint.v1.betaAppLocalizations.id(localizationId).delete
        )
    }

    private func map(
        _ sdk: AppStoreConnect_Swift_SDK.BetaAppLocalization,
        fallbackAppId: String
    ) -> Domain.BetaAppLocalization {
        let appId = sdk.relationships?.app?.data?.id ?? fallbackAppId
        return Domain.BetaAppLocalization(
            id: sdk.id,
            appId: appId,
            locale: sdk.attributes?.locale ?? "",
            description: sdk.attributes?.description,
            feedbackEmail: sdk.attributes?.feedbackEmail,
            marketingUrl: sdk.attributes?.marketingURL,
            privacyPolicyUrl: sdk.attributes?.privacyPolicyURL,
            tvOsPrivacyPolicy: sdk.attributes?.tvOsPrivacyPolicy
        )
    }
}
