@preconcurrency import AppStoreConnect_Swift_SDK
import Domain
import Foundation

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

    public func getVersion(id: String) async throws -> Domain.AppStoreVersion {
        let request = APIEndpoint.v1.appStoreVersions.id(id).get(
            parameters: .init(include: [.app, .build])
        )
        let response = try await client.request(request)
        let appId = response.data.relationships?.app?.data?.id ?? ""
        let buildId = response.data.relationships?.build?.data?.id
        guard let version = mapVersion(response.data, appId: appId, buildId: buildId) else {
            throw Domain.APIError.unknown("Failed to map version \(id)")
        }
        return version
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

    public func updateVersion(
        id: String,
        versionString: String?,
        copyright: String?,
        releaseType: String?,
        earliestReleaseDate: String?
    ) async throws -> Domain.AppStoreVersion {
        // Only send the fields the caller actually wants to change. Apple's
        // SDK uses `encodeIfPresent`, so nil keys never reach the wire and
        // unchanged attributes are preserved server-side.
        let parsedReleaseType = releaseType.flatMap {
            AppStoreVersionUpdateRequest.Data.Attributes.ReleaseType(rawValue: $0)
        }
        let parsedReleaseDate: Date? = earliestReleaseDate.flatMap { ISO8601DateFormatter().date(from: $0) }
        let body = AppStoreVersionUpdateRequest(
            data: .init(
                type: .appStoreVersions,
                id: id,
                attributes: .init(
                    versionString: versionString,
                    copyright: copyright,
                    releaseType: parsedReleaseType,
                    earliestReleaseDate: parsedReleaseDate
                )
            )
        )
        let response = try await client.request(APIEndpoint.v1.appStoreVersions.id(id).patch(body))
        let appId = response.data.relationships?.app?.data?.id ?? ""
        guard let version = mapVersion(response.data, appId: appId) else {
            throw Domain.APIError.unknown("Failed to map updated version \(id)")
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
        appId: String,
        buildId: String? = nil
    ) -> Domain.AppStoreVersion? {
        guard let platform = Domain.AppStorePlatform(
            rawValue: sdkVersion.attributes?.platform?.rawValue ?? ""
        ) else { return nil }
        let state = Domain.AppStoreVersionState(
            rawValue: sdkVersion.attributes?.appStoreState?.rawValue ?? ""
        ) ?? .prepareForSubmission
        // Hoist the three editable attributes onto the Domain so the web
        // client's GET /versions/:id round-trip reflects what was just
        // PATCHed. ISO-formatting `earliestReleaseDate` keeps the Domain
        // free of Date plumbing.
        let isoFormatter = ISO8601DateFormatter()
        let earliestReleaseDate: String? = sdkVersion.attributes?.earliestReleaseDate
            .map { isoFormatter.string(from: $0) }
        return Domain.AppStoreVersion(
            id: sdkVersion.id,
            appId: appId,
            versionString: sdkVersion.attributes?.versionString ?? "",
            platform: platform,
            state: state,
            buildId: buildId,
            copyright: sdkVersion.attributes?.copyright,
            releaseType: sdkVersion.attributes?.releaseType?.rawValue,
            earliestReleaseDate: earliestReleaseDate
        )
    }
}
