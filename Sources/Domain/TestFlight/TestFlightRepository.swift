import Mockable

@Mockable
public protocol TestFlightRepository: Sendable {
    func listBetaGroups(appId: String?, limit: Int?) async throws -> PaginatedResponse<BetaGroup>
    func listBetaTesters(groupId: String?, limit: Int?) async throws -> PaginatedResponse<BetaTester>
}
