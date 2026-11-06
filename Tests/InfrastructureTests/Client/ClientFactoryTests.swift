@preconcurrency import AppStoreConnect_Swift_SDK
import CryptoKit
import Foundation
import Mockable
import Testing
@testable import Domain
@testable import Infrastructure

@Suite
struct ClientFactoryTests {

    private static let privateKeyPEM = P256.Signing.PrivateKey().pemRepresentation

    @Test func `should sign requests as the key's user when the key is an individual key`() async throws {
        let claims = try await tokenClaims(
            for: AuthCredentials(keyID: "KEY123", issuerID: nil, privateKeyPEM: Self.privateKeyPEM)
        )

        #expect(claims["sub"] as? String == "user")
        #expect(claims["iss"] == nil)
    }

    @Test func `should sign requests with the issuer ID when the key is a team key`() async throws {
        let claims = try await tokenClaims(
            for: AuthCredentials(keyID: "KEY123", issuerID: "ISSUER456", privateKeyPEM: Self.privateKeyPEM)
        )

        #expect(claims["iss"] as? String == "ISSUER456")
        #expect(claims["sub"] == nil)
    }

    /// Sends one request through a provider built from `credentials` and decodes the claims
    /// of the JWT in its `Authorization` header.
    private func tokenClaims(for credentials: AuthCredentials) async throws -> [String: Any] {
        let authProvider = MockAuthProvider()
        given(authProvider).resolve().willReturn(credentials)
        let executor = CapturingRequestExecutor()
        let provider = try ClientFactory().makeProvider(authProvider: authProvider, requestExecutor: executor)

        _ = try? await provider.request(APIEndpoint.v1.apps.get())

        let authorization = try #require(executor.requests.first?.value(forHTTPHeaderField: "Authorization"))
        let payload = try #require(authorization.split(separator: ".").dropFirst().first)
        var base64 = payload.replacingOccurrences(of: "-", with: "+").replacingOccurrences(of: "_", with: "/")
        base64 += String(repeating: "=", count: (4 - base64.count % 4) % 4)
        let data = try #require(Data(base64Encoded: base64))
        return try #require(try JSONSerialization.jsonObject(with: data) as? [String: Any])
    }
}

/// Records each request and fails it, so a test can see what would have been sent to App Store Connect.
private final class CapturingRequestExecutor: RequestExecutor, @unchecked Sendable {
    private(set) var requests: [URLRequest] = []

    func execute(_ urlRequest: URLRequest, completion: @escaping (Result<Response<Data>, Error>) -> Void) {
        requests.append(urlRequest)
        completion(.failure(URLError(.notConnectedToInternet)))
    }

    func download(_ urlRequest: URLRequest, completion: @escaping (Result<Response<URL>, Error>) -> Void) {
        requests.append(urlRequest)
        completion(.failure(URLError(.notConnectedToInternet)))
    }
}
