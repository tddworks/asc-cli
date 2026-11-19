import Mockable

@Mockable
public protocol Territories: Sendable {
    func listTerritories() async throws -> [Territory]
}
