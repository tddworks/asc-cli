@preconcurrency import AppStoreConnect_Swift_SDK
import Domain

public struct SDKBuildRepository: BuildRepository, @unchecked Sendable {
    private let client: any APIClient

    public init(client: any APIClient) {
        self.client = client
    }

    public func listBuilds(appId: String?, limit: Int?) async throws -> PaginatedResponse<Domain.Build> {
        var filterApp: [String]?
        if let appId {
            filterApp = [appId]
        }

        let request = APIEndpoint.v1.builds.get(parameters: .init(
            filterApp: filterApp,
            limit: limit
        ))
        let response = try await client.request(request)
        let builds = response.data.map { mapBuild($0) }
        let nextCursor = response.links.next
        return PaginatedResponse(data: builds, nextCursor: nextCursor)
    }

    public func getBuild(id: String) async throws -> Domain.Build {
        let request = APIEndpoint.v1.builds.id(id).get()
        let response = try await client.request(request)
        return mapBuild(response.data)
    }

    private func mapBuild(_ sdkBuild: AppStoreConnect_Swift_SDK.Build) -> Domain.Build {
        Domain.Build(
            id: sdkBuild.id,
            version: sdkBuild.attributes?.version ?? "",
            uploadedDate: sdkBuild.attributes?.uploadedDate,
            expirationDate: sdkBuild.attributes?.expirationDate,
            expired: sdkBuild.attributes?.isExpired ?? false,
            processingState: mapProcessingState(sdkBuild.attributes?.processingState),
            buildNumber: nil
        )
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
