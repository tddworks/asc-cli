import AppStoreConnect_Swift_SDK
import Domain
import Foundation

public struct ClientFactory: Sendable {

    public init() {}

    public func makeAppRepository(authProvider: any AuthProvider) throws -> any AppRepository {
        let provider = try makeProvider(authProvider: authProvider)
        return SDKAppRepository(provider: provider)
    }

    public func makeBuildRepository(authProvider: any AuthProvider) throws -> any BuildRepository {
        let provider = try makeProvider(authProvider: authProvider)
        return SDKBuildRepository(provider: provider)
    }

    public func makeTestFlightRepository(authProvider: any AuthProvider) throws -> any TestFlightRepository {
        let provider = try makeProvider(authProvider: authProvider)
        return SDKTestFlightRepository(provider: provider)
    }

    public func makeScreenshotRepository(authProvider: any AuthProvider) throws -> any ScreenshotRepository {
        let provider = try makeProvider(authProvider: authProvider)
        return SDKScreenshotRepository(provider: provider)
    }

    private func makeProvider(authProvider: any AuthProvider) throws -> APIProvider {
        let credentials = try authProvider.resolve()
        let strippedKey = credentials.privateKeyPEM
            .replacingOccurrences(of: "-----BEGIN PRIVATE KEY-----", with: "")
            .replacingOccurrences(of: "-----END PRIVATE KEY-----", with: "")
            .replacingOccurrences(of: "-----BEGIN EC PRIVATE KEY-----", with: "")
            .replacingOccurrences(of: "-----END EC PRIVATE KEY-----", with: "")
            .replacingOccurrences(of: "\n", with: "")
            .trimmingCharacters(in: .whitespaces)
        let configuration = try APIConfiguration(
            issuerID: credentials.issuerID,
            privateKeyID: credentials.keyID,
            privateKey: strippedKey
        )
        return APIProvider(configuration: configuration)
    }
}
