@preconcurrency import AppStoreConnect_Swift_SDK
import Foundation

public struct SDKLocalizationRepository: VersionLocalizationRepository, @unchecked Sendable {
    private let client: any APIClient

    public init(client: any APIClient) {
        self.client = client
    }

    public func listLocalizations(versionId: String) async throws -> [ASCKit.AppStoreVersionLocalization] {
        let request = APIEndpoint.v1.appStoreVersions.id(versionId).appStoreVersionLocalizations.get()
        let response = try await client.request(request)
        return response.data.map { mapLocalization($0, versionId: versionId) }
    }

    public func createLocalization(versionId: String, locale: String) async throws -> ASCKit.AppStoreVersionLocalization {
        let body = AppStoreVersionLocalizationCreateRequest(
            data: .init(
                type: .appStoreVersionLocalizations,
                attributes: .init(locale: locale),
                relationships: .init(appStoreVersion: .init(data: .init(type: .appStoreVersions, id: versionId)))
            )
        )
        let response = try await client.request(APIEndpoint.v1.appStoreVersionLocalizations.post(body))
        return mapLocalization(response.data, versionId: versionId)
    }

    public func updateLocalization(
        localizationId: String,
        whatsNew: String?,
        description: String?,
        keywords: String?,
        marketingUrl: String?,
        supportUrl: String?,
        promotionalText: String?
    ) async throws -> ASCKit.AppStoreVersionLocalization {
        let body = AppStoreVersionLocalizationUpdateRequest(
            data: .init(
                type: .appStoreVersionLocalizations,
                id: localizationId,
                attributes: .init(
                    description: description,
                    keywords: keywords,
                    marketingURL: marketingUrl.flatMap { URL(string: $0) },
                    promotionalText: promotionalText,
                    supportURL: supportUrl.flatMap { URL(string: $0) },
                    whatsNew: whatsNew
                )
            )
        )
        let response = try await client.request(APIEndpoint.v1.appStoreVersionLocalizations.id(localizationId).patch(body))
        return mapLocalization(response.data, versionId: localizationId)
    }

    // MARK: - Mapper

    private func mapLocalization(
        _ sdkLoc: AppStoreConnect_Swift_SDK.AppStoreVersionLocalization,
        versionId: String
    ) -> ASCKit.AppStoreVersionLocalization {
        ASCKit.AppStoreVersionLocalization(
            id: sdkLoc.id,
            versionId: versionId,
            locale: sdkLoc.attributes?.locale ?? "",
            whatsNew: sdkLoc.attributes?.whatsNew,
            description: sdkLoc.attributes?.description,
            keywords: sdkLoc.attributes?.keywords,
            marketingUrl: sdkLoc.attributes?.marketingURL?.absoluteString,
            supportUrl: sdkLoc.attributes?.supportURL?.absoluteString,
            promotionalText: sdkLoc.attributes?.promotionalText
        )
    }
}
