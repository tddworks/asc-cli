import Domain
import Infrastructure

struct ClientProvider {
    static func makeAppRepository() throws -> any AppRepository {
        let authProvider = CompositeAuthProvider()
        let factory = ClientFactory()
        return try factory.makeAppRepository(authProvider: authProvider)
    }

    static func makeVersionRepository() throws -> any VersionRepository {
        let authProvider = CompositeAuthProvider()
        let factory = ClientFactory()
        return try factory.makeVersionRepository(authProvider: authProvider)
    }

    static func makeBuildRepository() throws -> any BuildRepository {
        let authProvider = CompositeAuthProvider()
        let factory = ClientFactory()
        return try factory.makeBuildRepository(authProvider: authProvider)
    }

    static func makeTestFlightRepository() throws -> any TestFlightRepository {
        let authProvider = CompositeAuthProvider()
        let factory = ClientFactory()
        return try factory.makeTestFlightRepository(authProvider: authProvider)
    }

    static func makeVersionLocalizationRepository() throws -> any VersionLocalizationRepository {
        let authProvider = CompositeAuthProvider()
        let factory = ClientFactory()
        return try factory.makeVersionLocalizationRepository(authProvider: authProvider)
    }

    static func makeScreenshotRepository() throws -> any ScreenshotRepository {
        let authProvider = CompositeAuthProvider()
        let factory = ClientFactory()
        return try factory.makeScreenshotRepository(authProvider: authProvider)
    }

    static func makeAppInfoRepository() throws -> any AppInfoRepository {
        let authProvider = CompositeAuthProvider()
        let factory = ClientFactory()
        return try factory.makeAppInfoRepository(authProvider: authProvider)
    }

    static func makeSubmissionRepository() throws -> any SubmissionRepository {
        let authProvider = CompositeAuthProvider()
        let factory = ClientFactory()
        return try factory.makeSubmissionRepository(authProvider: authProvider)
    }

    static func makeBundleIDRepository() throws -> any BundleIDRepository {
        let authProvider = CompositeAuthProvider()
        let factory = ClientFactory()
        return try factory.makeBundleIDRepository(authProvider: authProvider)
    }

    static func makeCertificateRepository() throws -> any CertificateRepository {
        let authProvider = CompositeAuthProvider()
        let factory = ClientFactory()
        return try factory.makeCertificateRepository(authProvider: authProvider)
    }

    static func makeDeviceRepository() throws -> any DeviceRepository {
        let authProvider = CompositeAuthProvider()
        let factory = ClientFactory()
        return try factory.makeDeviceRepository(authProvider: authProvider)
    }

    static func makeProfileRepository() throws -> any ProfileRepository {
        let authProvider = CompositeAuthProvider()
        let factory = ClientFactory()
        return try factory.makeProfileRepository(authProvider: authProvider)
    }

    static func makeBuildUploadRepository() throws -> any BuildUploadRepository {
        let authProvider = CompositeAuthProvider()
        let factory = ClientFactory()
        return try factory.makeBuildUploadRepository(authProvider: authProvider)
    }

    static func makeBetaBuildLocalizationRepository() throws -> any BetaBuildLocalizationRepository {
        let authProvider = CompositeAuthProvider()
        let factory = ClientFactory()
        return try factory.makeBetaBuildLocalizationRepository(authProvider: authProvider)
    }

    static func makeReviewDetailRepository() throws -> any ReviewDetailRepository {
        let authProvider = CompositeAuthProvider()
        let factory = ClientFactory()
        return try factory.makeReviewDetailRepository(authProvider: authProvider)
    }

    static func makePricingRepository() throws -> any PricingRepository {
        let authProvider = CompositeAuthProvider()
        let factory = ClientFactory()
        return try factory.makePricingRepository(authProvider: authProvider)
    }

    static func makePreviewRepository() throws -> any PreviewRepository {
        let authProvider = CompositeAuthProvider()
        let factory = ClientFactory()
        return try factory.makePreviewRepository(authProvider: authProvider)
    }
}
