@preconcurrency import AppStoreConnect_Swift_SDK
import Domain

public struct SDKVersionRepository: VersionRepository, @unchecked Sendable {
    private let client: any APIClient

    public init(client: any APIClient) {
        self.client = client
    }

    public func listVersions(appId: String) async throws -> [Domain.AppStoreVersion] {
        let request = APIEndpoint.v1.apps.id(appId).appStoreVersions.get()
        let response = try await client.request(request)
        return response.data.compactMap { mapVersion($0, appId: appId) }
    }

    public func createVersion(appId: String, versionString: String, platform: Domain.AppStorePlatform) async throws -> Domain.AppStoreVersion {
        guard let sdkPlatform = AppStoreConnect_Swift_SDK.Platform(rawValue: platform.rawValue) else {
            throw Domain.APIError.unknown("Unsupported platform for create: \(platform.rawValue)")
        }
        let body = AppStoreVersionCreateRequest(
            data: .init(
                type: .appStoreVersions,
                attributes: .init(platform: sdkPlatform, versionString: versionString),
                relationships: .init(app: .init(data: .init(type: .apps, id: appId)))
            )
        )
        let response = try await client.request(APIEndpoint.v1.appStoreVersions.post(body))
        guard let version = mapVersion(response.data, appId: appId) else {
            throw Domain.APIError.unknown("Failed to map created version")
        }
        return version
    }

    public func setBuild(versionId: String, buildId: String) async throws {
        let body = AppStoreVersionUpdateRequest(
            data: .init(
                type: .appStoreVersions,
                id: versionId,
                relationships: .init(
                    build: .init(data: .init(type: .builds, id: buildId))
                )
            )
        )
        _ = try await client.request(APIEndpoint.v1.appStoreVersions.id(versionId).patch(body))
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
}
