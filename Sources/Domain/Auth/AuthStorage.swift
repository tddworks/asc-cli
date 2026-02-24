import Mockable

@Mockable
public protocol AuthStorage: Sendable {
    func save(_ credentials: AuthCredentials) throws
    func load() throws -> AuthCredentials?
    func delete() throws
}
