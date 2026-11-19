import Mockable

@Mockable
public protocol AuthStorage: Sendable {
    func save(_ credentials: AuthCredentials, name: String) throws
    func load(name: String?) throws -> AuthCredentials?
    func loadAll() throws -> [ConnectAccount]
    func delete(name: String?) throws
    func setActive(name: String) throws
}
