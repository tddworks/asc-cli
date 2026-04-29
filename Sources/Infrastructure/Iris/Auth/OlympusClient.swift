import Foundation

/// Fetches team metadata from `https://appstoreconnect.apple.com/olympus/v1/session`
/// after a successful login. Surfaces the providerID / teamId / userEmail that ASC's
/// own web UI displays in the upper-right corner.
public struct OlympusClient: Sendable {
    private let session: URLSession
    private static let url = URL(string: "https://appstoreconnect.apple.com/olympus/v1/session")!

    public init(session: URLSession = .shared) {
        self.session = session
    }

    public struct OlympusSession: Sendable, Equatable {
        public let providerID: Int64?
        public let teamId: String?
        public let userEmail: String
    }

    public func fetchSession(cookies: String) async throws -> OlympusSession {
        var request = URLRequest(url: Self.url)
        request.httpMethod = "GET"
        request.setValue(cookies, forHTTPHeaderField: "Cookie")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("https://appstoreconnect.apple.com", forHTTPHeaderField: "Origin")

        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            let status = (response as? HTTPURLResponse)?.statusCode ?? -1
            throw OlympusError.httpFailure(status: status)
        }
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw OlympusError.malformedResponse
        }
        let user = json["user"] as? [String: Any]
        let provider = json["provider"] as? [String: Any]
        let userEmail = (user?["emailAddress"] as? String) ?? (user?["fullName"] as? String) ?? ""
        let providerID = provider?["providerId"] as? Int64
            ?? (provider?["providerId"] as? Int).map(Int64.init)
        let teamId = provider?["publicProviderId"] as? String
        return OlympusSession(providerID: providerID, teamId: teamId, userEmail: userEmail)
    }

    public enum OlympusError: LocalizedError {
        case httpFailure(status: Int)
        case malformedResponse

        public var errorDescription: String? {
            switch self {
            case .httpFailure(let status): return "olympus session failed: HTTP \(status)"
            case .malformedResponse: return "olympus session returned malformed JSON"
            }
        }
    }
}
