import Domain
import Infrastructure

struct ClientProvider {
    static func makeRepositories() throws -> (
        apps: any AppRepository,
        builds: any BuildRepository,
        testFlight: any TestFlightRepository
    ) {
        let authProvider = EnvironmentAuthProvider()
        let factory = ClientFactory()
        let client = try factory.makeClient(authProvider: authProvider)

        return (
            apps: OpenAPIAppRepository(client: client),
            builds: OpenAPIBuildRepository(client: client),
            testFlight: OpenAPITestFlightRepository(client: client)
        )
    }
}
