import Domain
import Infrastructure

struct ClientProvider {
    static func makeAppRepository() throws -> any AppRepository {
        let authProvider = EnvironmentAuthProvider()
        let factory = ClientFactory()
        return try factory.makeAppRepository(authProvider: authProvider)
    }

    static func makeBuildRepository() throws -> any BuildRepository {
        let authProvider = EnvironmentAuthProvider()
        let factory = ClientFactory()
        return try factory.makeBuildRepository(authProvider: authProvider)
    }

    static func makeTestFlightRepository() throws -> any TestFlightRepository {
        let authProvider = EnvironmentAuthProvider()
        let factory = ClientFactory()
        return try factory.makeTestFlightRepository(authProvider: authProvider)
    }

    static func makeScreenshotRepository() throws -> any ScreenshotRepository {
        let authProvider = EnvironmentAuthProvider()
        let factory = ClientFactory()
        return try factory.makeScreenshotRepository(authProvider: authProvider)
    }
}
