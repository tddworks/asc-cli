import Domain
import Infrastructure

struct ClientProvider {
    static func makeAppRepository() throws -> any AppRepository {
        let authProvider = CompositeAuthProvider()
        let factory = ClientFactory()
        return try factory.makeAppRepository(authProvider: authProvider)
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
}
