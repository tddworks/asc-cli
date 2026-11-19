import Mockable

@Mockable
public protocol TestFlightRepository: Sendable {
    func listBetaGroups(appId: String?, limit: Int?) async throws -> PaginatedResponse<BetaGroup>
    func createBetaGroup(
        appId: String,
        name: String,
        isInternalGroup: Bool,
        publicLinkEnabled: Bool?,
        feedbackEnabled: Bool?
    ) async throws -> BetaGroup
    func listBetaTesters(groupId: String, limit: Int?) async throws -> PaginatedResponse<BetaTester>
    func addBetaTester(groupId: String, email: String, firstName: String?, lastName: String?) async throws -> BetaTester
    func removeBetaTester(groupId: String, testerId: String) async throws
}
