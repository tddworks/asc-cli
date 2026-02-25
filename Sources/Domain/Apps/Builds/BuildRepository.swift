import Mockable

@Mockable
public protocol BuildRepository: Sendable {
    func listBuilds(appId: String?, limit: Int?) async throws -> PaginatedResponse<Build>
    func getBuild(id: String) async throws -> Build
    func addBetaGroups(buildId: String, betaGroupIds: [String]) async throws
    func removeBetaGroups(buildId: String, betaGroupIds: [String]) async throws
}
