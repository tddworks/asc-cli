import Foundation

/// A protocol abstracting HTTP data fetching for testability.
public protocol HTTPPerforming: Sendable {
    func data(for request: URLRequest) async throws -> (Data, URLResponse)
}

extension URLSession: HTTPPerforming {}
