import AppStoreConnect_Swift_SDK
import Domain
import Foundation

public struct ClientFactory: Sendable {

    public init() {}

    public func makeAppRepository(authProvider: any AuthProvider) throws -> any AppRepository {
        let provider = try makeProvider(authProvider: authProvider)
        return SDKAppRepository(client: provider)
    }

    public func makeVersionRepository(authProvider: any AuthProvider) throws -> any VersionRepository {
        let provider = try makeProvider(authProvider: authProvider)
        return SDKVersionRepository(client: provider)
    }

    public func makeBuildRepository(authProvider: any AuthProvider) throws -> any BuildRepository {
        let provider = try makeProvider(authProvider: authProvider)
        return SDKBuildRepository(client: provider)
    }

    public func makeTestFlightRepository(authProvider: any AuthProvider) throws -> any TestFlightRepository {
        let provider = try makeProvider(authProvider: authProvider)
        return SDKTestFlightRepository(client: provider)
    }

    public func makeVersionLocalizationRepository(authProvider: any AuthProvider) throws -> any VersionLocalizationRepository {
        let provider = try makeProvider(authProvider: authProvider)
        return SDKLocalizationRepository(client: provider)
    }

    public func makeScreenshotRepository(authProvider: any AuthProvider) throws -> any ScreenshotRepository {
        let provider = try makeProvider(authProvider: authProvider)
        return SDKScreenshotRepository(client: provider)
    }

    public func makeAppInfoRepository(authProvider: any AuthProvider) throws -> any AppInfoRepository {
        let provider = try makeProvider(authProvider: authProvider)
        return SDKAppInfoRepository(client: provider)
    }

    public func makeSubmissionRepository(authProvider: any AuthProvider) throws -> any SubmissionRepository {
        let provider = try makeProvider(authProvider: authProvider)
        return OpenAPISubmissionRepository(client: provider)
    }

    public func makeBundleIDRepository(authProvider: any AuthProvider) throws -> any BundleIDRepository {
        let provider = try makeProvider(authProvider: authProvider)
        return SDKBundleIDRepository(client: provider)
    }

    public func makeCertificateRepository(authProvider: any AuthProvider) throws -> any CertificateRepository {
        let provider = try makeProvider(authProvider: authProvider)
        return SDKCertificateRepository(client: provider)
    }

    public func makeDeviceRepository(authProvider: any AuthProvider) throws -> any DeviceRepository {
        let provider = try makeProvider(authProvider: authProvider)
        return SDKDeviceRepository(client: provider)
    }

    public func makeProfileRepository(authProvider: any AuthProvider) throws -> any ProfileRepository {
        let provider = try makeProvider(authProvider: authProvider)
        return SDKProfileRepository(client: provider)
    }

    public func makeBuildUploadRepository(authProvider: any AuthProvider) throws -> any BuildUploadRepository {
        let provider = try makeProvider(authProvider: authProvider)
        return SDKBuildUploadRepository(client: provider)
    }

    public func makeBetaBuildLocalizationRepository(authProvider: any AuthProvider) throws -> any BetaBuildLocalizationRepository {
        let provider = try makeProvider(authProvider: authProvider)
        return SDKBetaBuildLocalizationRepository(client: provider)
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
