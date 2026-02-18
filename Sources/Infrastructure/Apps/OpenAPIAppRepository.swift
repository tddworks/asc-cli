@preconcurrency import AppStoreConnect_Swift_SDK
import Domain

public struct SDKAppRepository: AppRepository, @unchecked Sendable {
    private let provider: APIProvider

    public init(provider: APIProvider) {
        self.provider = provider
    }

    public func listApps(limit: Int?) async throws -> PaginatedResponse<Domain.App> {
        let request = APIEndpoint.v1.apps.get(parameters: .init(
            limit: limit
        ))
        let response = try await provider.request(request)
        let apps = response.data.map { mapApp($0) }
        let nextCursor = response.links.next
        return PaginatedResponse(data: apps, nextCursor: nextCursor)
    }

    public func getApp(id: String) async throws -> Domain.App {
        let request = APIEndpoint.v1.apps.id(id).get()
        let response = try await provider.request(request)
        return mapApp(response.data)
    }

    public func listVersions(appId: String) async throws -> [Domain.AppStoreVersion] {
        let request = APIEndpoint.v1.apps.id(appId).appStoreVersions.get()
        let response = try await provider.request(request)
        return response.data.compactMap { mapVersion($0, appId: appId) }
    }

    private func mapVersion(
        _ sdkVersion: AppStoreConnect_Swift_SDK.AppStoreVersion,
        appId: String
    ) -> Domain.AppStoreVersion? {
        guard let platform = Domain.AppStorePlatform(
            rawValue: sdkVersion.attributes?.platform?.rawValue ?? ""
        ) else { return nil }
        let state = Domain.AppStoreVersionState(
            rawValue: sdkVersion.attributes?.appStoreState?.rawValue ?? ""
        ) ?? .prepareForSubmission
        return Domain.AppStoreVersion(
            id: sdkVersion.id,
            appId: appId,
            versionString: sdkVersion.attributes?.versionString ?? "",
            platform: platform,
            state: state
        )
    }

    private func mapApp(_ sdkApp: AppStoreConnect_Swift_SDK.App) -> Domain.App {
        Domain.App(
            id: sdkApp.id,
            name: sdkApp.attributes?.name ?? "",
            bundleId: sdkApp.attributes?.bundleID ?? "",
            sku: sdkApp.attributes?.sku,
            primaryLocale: sdkApp.attributes?.primaryLocale
        )
    }
}
