import Mockable

@Mockable
public protocol BuildRepository: Sendable {
    func listBuilds(appId: String?, limit: Int?) async throws -> PaginatedResponse<Build>
    func getBuild(id: String) async throws -> Build
}
