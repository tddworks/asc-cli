import Mockable

@Mockable
public protocol AppRepository: Sendable {
    func listApps(limit: Int?) async throws -> PaginatedResponse<App>
    func getApp(id: String) async throws -> App
    func listVersions(appId: String) async throws -> [AppStoreVersion]
}
