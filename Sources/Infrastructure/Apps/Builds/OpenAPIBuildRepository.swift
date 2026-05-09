@preconcurrency import AppStoreConnect_Swift_SDK
import Domain

public struct SDKBuildRepository: BuildRepository, @unchecked Sendable {
    private let client: any APIClient

    public init(client: any APIClient) {
        self.client = client
    }

    public func listBuilds(appId: String?, platform: BuildUploadPlatform?, version: String?, limit: Int?) async throws -> PaginatedResponse<Domain.Build> {
        var filterApp: [String]?
        if let appId {
            filterApp = [appId]
        }

        let filterPlatform: [APIEndpoint.V1.Builds.GetParameters.FilterPreReleaseVersionPlatform]?
        if let platform {
            let sdkPlatform = APIEndpoint.V1.Builds.GetParameters.FilterPreReleaseVersionPlatform(rawValue: platform.rawValue)
            filterPlatform = sdkPlatform.map { [$0] }
        } else {
            filterPlatform = nil
        }

        let filterVersion: [String]? = version.map { [$0] }

        let request = APIEndpoint.v1.builds.get(parameters: .init(
            filterPreReleaseVersionVersion: filterVersion,
            filterPreReleaseVersionPlatform: filterPlatform,
            filterApp: filterApp,
            sort: [.minusuploadedDate],
            limit: limit,
            include: [.preReleaseVersion]
        ))
        let response = try await client.request(request)

        // Build a lookup of preReleaseVersion ID → PrereleaseVersion from included resources
        var preReleaseVersions: [String: PrereleaseVersion] = [:]
        for item in response.included ?? [] {
            if case .prereleaseVersion(let prv) = item {
                preReleaseVersions[prv.id] = prv
            }
        }

        let builds = response.data.map { sdkBuild in
            let prvId = sdkBuild.relationships?.preReleaseVersion?.data?.id
            let prv = prvId.flatMap { preReleaseVersions[$0] }
            return mapBuild(sdkBuild, preReleaseVersion: prv)
        }
        let nextCursor = response.links.next
        return PaginatedResponse(data: builds, nextCursor: nextCursor)
    }

    public func getBuild(id: String) async throws -> Domain.Build {
        let request = APIEndpoint.v1.builds.id(id).get()
        let response = try await client.request(request)
        return mapBuild(response.data)
    }

    public func addBetaGroups(buildId: String, betaGroupIds: [String]) async throws {
        let body = BuildBetaGroupsLinkagesRequest(
            data: betaGroupIds.map { .init(type: .betaGroups, id: $0) }
        )
        try await client.request(APIEndpoint.v1.builds.id(buildId).relationships.betaGroups.post(body))
    }

    public func removeBetaGroups(buildId: String, betaGroupIds: [String]) async throws {
        let body = BuildBetaGroupsLinkagesRequest(
            data: betaGroupIds.map { .init(type: .betaGroups, id: $0) }
        )
        try await client.request(APIEndpoint.v1.builds.id(buildId).relationships.betaGroups.delete(body))
    }

    public func updateBuildEncryptionCompliance(buildId: String, usesNonExemptEncryption: Bool) async throws -> Domain.Build {
        let body = BuildUpdateRequest(
            data: .init(
                type: .builds,
                id: buildId,
                attributes: .init(usesNonExemptEncryption: usesNonExemptEncryption)
            )
        )
        let response = try await client.request(APIEndpoint.v1.builds.id(buildId).patch(body))
        return mapBuild(response.data)
    }

    private func mapBuild(_ sdkBuild: AppStoreConnect_Swift_SDK.Build, preReleaseVersion: PrereleaseVersion? = nil) -> Domain.Build {
        let buildString = sdkBuild.attributes?.version
        let marketingVersion = preReleaseVersion?.attributes?.version
        let platform = preReleaseVersion?.attributes?.platform.flatMap { mapPlatform($0) }

        return Domain.Build(
            id: sdkBuild.id,
            version: marketingVersion ?? buildString ?? "",
            uploadedDate: sdkBuild.attributes?.uploadedDate,
            expirationDate: sdkBuild.attributes?.expirationDate,
            expired: sdkBuild.attributes?.isExpired ?? false,
            processingState: mapProcessingState(sdkBuild.attributes?.processingState),
            buildNumber: buildString,
            platform: platform,
            usesNonExemptEncryption: sdkBuild.attributes?.usesNonExemptEncryption
        )
    }

    private func mapPlatform(_ sdkPlatform: Platform) -> BuildUploadPlatform? {
        switch sdkPlatform {
        case .ios: return .iOS
        case .macOs: return .macOS
        case .tvOs: return .tvOS
        case .visionOs: return .visionOS
        }
    }

    private func mapProcessingState(_ state: AppStoreConnect_Swift_SDK.Build.Attributes.ProcessingState?) -> Domain.Build.ProcessingState {
        guard let state else { return .processing }
        switch state {
        case .processing: return .processing
        case .failed: return .failed
        case .invalid: return .invalid
        case .valid: return .valid
        }
    }
}
