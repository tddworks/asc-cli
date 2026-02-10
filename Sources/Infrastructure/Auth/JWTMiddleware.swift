import Domain
import HTTPTypes
import OpenAPIRuntime

public struct JWTMiddleware: ClientMiddleware, Sendable {
    private let authProvider: any AuthProvider
    private let tokenGenerator: JWTTokenGenerator

    public init(authProvider: any AuthProvider, tokenGenerator: JWTTokenGenerator = JWTTokenGenerator()) {
        self.authProvider = authProvider
        self.tokenGenerator = tokenGenerator
    }

    public func intercept(
        _ request: HTTPRequest,
        body: HTTPBody?,
        baseURL: URL,
        operationID: String,
        next: @Sendable (HTTPRequest, HTTPBody?, URL) async throws -> (HTTPRequest, HTTPBody?)
    ) async throws -> (HTTPRequest, HTTPBody?) {
        var modifiedRequest = request
        let credentials = try authProvider.resolve()
        let token = try tokenGenerator.generateToken(credentials: credentials)
        modifiedRequest.headerFields[.authorization] = "Bearer \(token)"
        return try await next(modifiedRequest, body, baseURL)
    }
}
