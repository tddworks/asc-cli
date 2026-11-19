import Mockable

@Mockable
public protocol AuthProvider: Sendable {
    func resolve() throws -> AuthCredentials
}
