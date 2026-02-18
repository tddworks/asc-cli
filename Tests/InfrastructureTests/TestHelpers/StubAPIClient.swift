@preconcurrency import AppStoreConnect_Swift_SDK
@testable import Infrastructure

final class StubAPIClient: APIClient, @unchecked Sendable {
    private var stubbedResponse: Any?

    func willReturn<T>(_ response: T) {
        stubbedResponse = response
    }

    func request<T: Decodable>(_ endpoint: Request<T>) async throws -> T {
        guard let response = stubbedResponse as? T else {
            fatalError("StubAPIClient: no stub configured for \(T.self)")
        }
        return response
    }
}
