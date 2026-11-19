import Mockable

@Mockable
public protocol TerritoryRepository: Sendable {
    func listTerritories() async throws -> [Territory]
}
