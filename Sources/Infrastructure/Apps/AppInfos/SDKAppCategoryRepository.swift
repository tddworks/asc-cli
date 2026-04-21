@preconcurrency import AppStoreConnect_Swift_SDK
import Domain

public struct SDKAppCategoryRepository: AppCategoryRepository, @unchecked Sendable {
    private let client: any APIClient

    public init(client: any APIClient) {
        self.client = client
    }

    public func listCategories(platform: String?) async throws -> [Domain.AppCategory] {
        let filterPlatforms: [APIEndpoint.V1.AppCategories.GetParameters.FilterPlatforms]?
        if let platform {
            filterPlatforms = APIEndpoint.V1.AppCategories.GetParameters.FilterPlatforms(rawValue: platform).map { [$0] } ?? []
        } else {
            filterPlatforms = nil
        }
        let parameters = APIEndpoint.V1.AppCategories.GetParameters(
            filterPlatforms: filterPlatforms,
            include: [.subcategories]
        )
        let request = APIEndpoint.v1.appCategories.get(parameters: parameters)
        let response = try await client.request(request)
        let topLevel = response.data.map { mapCategory($0) }
        let subcategories = (response.included ?? []).map { mapCategory($0) }
        return topLevel + subcategories
    }

    public func getCategory(id: String) async throws -> Domain.AppCategory {
        let request = APIEndpoint.v1.appCategories.id(id).get()
        let response = try await client.request(request)
        return mapCategory(response.data)
    }

    // MARK: - Mapper

    private func mapCategory(_ sdkCategory: AppStoreConnect_Swift_SDK.AppCategory) -> Domain.AppCategory {
        let platforms = sdkCategory.attributes?.platforms?.map { $0.rawValue } ?? []
        let parentId = sdkCategory.relationships?.parent?.data?.id
        return Domain.AppCategory(id: sdkCategory.id, platforms: platforms, parentId: parentId)
    }
}
