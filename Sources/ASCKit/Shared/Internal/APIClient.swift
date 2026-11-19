@preconcurrency import AppStoreConnect_Swift_SDK

public protocol APIClient {
    func request<T: Decodable>(_ endpoint: Request<T>) async throws -> T
    func request(_ endpoint: Request<Void>) async throws
}

extension APIProvider: APIClient {}

extension APIClient {
    /// Requests every page of a paginated list, re-sending `endpoint` with the next cursor
    /// until Apple stops returning one. Use it when the caller needs the complete list:
    /// Apple returns only its default page size (usually 50) when no `limit` is given, and
    /// per-territory lists reach 175 entries.
    func requestAllPages<T: Decodable>(
        _ endpoint: Request<T>,
        nextCursor: (T) -> String?
    ) async throws -> [T] {
        var pages: [T] = []
        var request = endpoint
        while true {
            let page = try await self.request(request)
            pages.append(page)
            guard let cursor = nextCursor(page) else { return pages }
            request.query = (endpoint.query ?? []) + [("cursor", cursor)]
        }
    }
}
