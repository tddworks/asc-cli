import Domain
import OpenAPIRuntime
import OpenAPIURLSession

public struct ClientFactory: Sendable {
    public static let appStoreConnectBaseURL = URL(string: "https://api.appstoreconnect.apple.com")!

    public init() {}

    public func makeClient(authProvider: any AuthProvider) throws -> Client {
        let middleware = JWTMiddleware(authProvider: authProvider)
        return Client(
            serverURL: Self.appStoreConnectBaseURL,
            transport: URLSessionTransport(),
            middlewares: [middleware]
        )
    }
}
