@preconcurrency import AppStoreConnect_Swift_SDK
import Domain

public struct SDKAppInfoRepository: AppInfoRepository, @unchecked Sendable {
    private let client: any APIClient

    public init(client: any APIClient) {
        self.client = client
    }

    public func listAppInfos(appId: String) async throws -> [Domain.AppInfo] {
        // Explicitly request category relationship fields — ASC omits them by default.
        let request = APIEndpoint.v1.apps.id(appId).appInfos.get(
            parameters: .init(
                fieldsAppInfos: [
                    .primaryCategory, .primarySubcategoryOne, .primarySubcategoryTwo,
                    .secondaryCategory, .secondarySubcategoryOne, .secondarySubcategoryTwo,
                ]
            )
        )
        let response = try await client.request(request)
        return response.data.map { mapAppInfo($0, appId: appId) }
    }

    public func listLocalizations(appInfoId: String) async throws -> [Domain.AppInfoLocalization] {
        let request = APIEndpoint.v1.appInfos.id(appInfoId).appInfoLocalizations.get()
        let response = try await client.request(request)
        return response.data.map { mapLocalization($0, appInfoId: appInfoId) }
    }

    public func createLocalization(appInfoId: String, locale: String, name: String) async throws -> Domain.AppInfoLocalization {
        let body = AppInfoLocalizationCreateRequest(
            data: .init(
                type: .appInfoLocalizations,
                attributes: .init(locale: locale, name: name),
                relationships: .init(appInfo: .init(data: .init(type: .appInfos, id: appInfoId)))
            )
        )
        let response = try await client.request(APIEndpoint.v1.appInfoLocalizations.post(body))
        return mapLocalization(response.data, appInfoId: appInfoId)
    }

    public func updateLocalization(id: String, name: String?, subtitle: String?, privacyPolicyUrl: String?, privacyChoicesUrl: String?, privacyPolicyText: String?) async throws -> Domain.AppInfoLocalization {
        let body = AppInfoLocalizationUpdateRequest(
            data: .init(
                type: .appInfoLocalizations,
                id: id,
                attributes: .init(name: name, subtitle: subtitle, privacyPolicyURL: privacyPolicyUrl, privacyChoicesURL: privacyChoicesUrl, privacyPolicyText: privacyPolicyText)
            )
        )
        let response = try await client.request(APIEndpoint.v1.appInfoLocalizations.id(id).patch(body))
        let appInfoId = response.data.relationships?.appInfo?.data?.id ?? ""
        return mapLocalization(response.data, appInfoId: appInfoId)
    }

    public func deleteLocalization(id: String) async throws {
        try await client.request(APIEndpoint.v1.appInfoLocalizations.id(id).delete)
    }

    public func updateCategories(
        id: String,
        primaryCategoryId: String?,
        primarySubcategoryOneId: String?,
        primarySubcategoryTwoId: String?,
        secondaryCategoryId: String?,
        secondarySubcategoryOneId: String?,
        secondarySubcategoryTwoId: String?
    ) async throws -> Domain.AppInfo {
        let relationships = AppInfoUpdateRequest.Data.Relationships(
            primaryCategory: primaryCategoryId.map { .init(data: .init(type: .appCategories, id: $0)) },
            primarySubcategoryOne: primarySubcategoryOneId.map { .init(data: .init(type: .appCategories, id: $0)) },
            primarySubcategoryTwo: primarySubcategoryTwoId.map { .init(data: .init(type: .appCategories, id: $0)) },
            secondaryCategory: secondaryCategoryId.map { .init(data: .init(type: .appCategories, id: $0)) },
            secondarySubcategoryOne: secondarySubcategoryOneId.map { .init(data: .init(type: .appCategories, id: $0)) },
            secondarySubcategoryTwo: secondarySubcategoryTwoId.map { .init(data: .init(type: .appCategories, id: $0)) }
        )
        let body = AppInfoUpdateRequest(data: .init(type: .appInfos, id: id, relationships: relationships))
        let response = try await client.request(APIEndpoint.v1.appInfos.id(id).patch(body))
        let appId = response.data.relationships?.app?.data?.id ?? ""
        return mapAppInfo(response.data, appId: appId)
    }

    // MARK: - Mappers

    private func mapAppInfo(
        _ sdkInfo: AppStoreConnect_Swift_SDK.AppInfo,
        appId: String
    ) -> Domain.AppInfo {
        Domain.AppInfo(
            id: sdkInfo.id,
            appId: appId,
            primaryCategoryId: sdkInfo.relationships?.primaryCategory?.data?.id,
            primarySubcategoryOneId: sdkInfo.relationships?.primarySubcategoryOne?.data?.id,
            primarySubcategoryTwoId: sdkInfo.relationships?.primarySubcategoryTwo?.data?.id,
            secondaryCategoryId: sdkInfo.relationships?.secondaryCategory?.data?.id,
            secondarySubcategoryOneId: sdkInfo.relationships?.secondarySubcategoryOne?.data?.id,
            secondarySubcategoryTwoId: sdkInfo.relationships?.secondarySubcategoryTwo?.data?.id
        )
    }

    private func mapLocalization(
        _ sdkLoc: AppStoreConnect_Swift_SDK.AppInfoLocalization,
        appInfoId: String
    ) -> Domain.AppInfoLocalization {
        Domain.AppInfoLocalization(
            id: sdkLoc.id,
            appInfoId: appInfoId,
            locale: sdkLoc.attributes?.locale ?? "",
            name: sdkLoc.attributes?.name,
            subtitle: sdkLoc.attributes?.subtitle,
            privacyPolicyUrl: sdkLoc.attributes?.privacyPolicyURL,
            privacyChoicesUrl: sdkLoc.attributes?.privacyChoicesURL,
            privacyPolicyText: sdkLoc.attributes?.privacyPolicyText
        )
    }
}
