@preconcurrency import AppStoreConnect_Swift_SDK
@testable import Infrastructure

final class SequencedStubAPIClient: APIClient, @unchecked Sendable {
    private var queue: [Any] = []

    func enqueue<T>(_ response: T) {
        queue.append(response)
    }

    func request<T: Decodable>(_ endpoint: Request<T>) async throws -> T {
        guard !queue.isEmpty else {
            fatalError("SequencedStubAPIClient: empty queue — no stub configured for \(T.self)")
        }
        let response = queue.removeFirst()
        guard let typed = response as? T else {
            fatalError("SequencedStubAPIClient: expected \(T.self) but got \(type(of: response))")
        }
        return typed
    }
}
