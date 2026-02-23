@preconcurrency import AppStoreConnect_Swift_SDK
import Domain

public struct SDKAppInfoRepository: AppInfoRepository, @unchecked Sendable {
    private let client: any APIClient

    public init(client: any APIClient) {
        self.client = client
    }

    public func listAppInfos(appId: String) async throws -> [Domain.AppInfo] {
        let request = APIEndpoint.v1.apps.id(appId).appInfos.get()
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

    public func updateLocalization(id: String, name: String?, subtitle: String?, privacyPolicyUrl: String?) async throws -> Domain.AppInfoLocalization {
        let body = AppInfoLocalizationUpdateRequest(
            data: .init(
                type: .appInfoLocalizations,
                id: id,
                attributes: .init(name: name, subtitle: subtitle, privacyPolicyURL: privacyPolicyUrl)
            )
        )
        let response = try await client.request(APIEndpoint.v1.appInfoLocalizations.id(id).patch(body))
        let appInfoId = response.data.relationships?.appInfo?.data?.id ?? ""
        return mapLocalization(response.data, appInfoId: appInfoId)
    }

    // MARK: - Mappers

    private func mapAppInfo(
        _ sdkInfo: AppStoreConnect_Swift_SDK.AppInfo,
        appId: String
    ) -> Domain.AppInfo {
        Domain.AppInfo(id: sdkInfo.id, appId: appId)
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
