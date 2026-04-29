import Domain
import Foundation

/// Implements `IrisInAppPurchaseStateRepository` against
/// `GET /iris/v1/apps/:appId/inAppPurchasesV2`. Apple's iris listing exposes
/// `submitWithNextAppStoreVersion` as an attribute on each IAP — the public SDK
/// does not, which is why this lives behind the iris cookie surface.
public struct IrisSDKInAppPurchaseStateRepository: IrisInAppPurchaseStateRepository, @unchecked Sendable {
    private let client: IrisClient

    public init(client: IrisClient = IrisClient()) {
        self.client = client
    }

    public func fetchSubmitFlags(session: IrisSession, appId: String) async throws -> [String: Bool] {
        let (data, _) = try await client.get(
            path: "apps/\(appId)/inAppPurchasesV2",
            queryItems: [
                // Narrow payload — only the field we need.
                URLQueryItem(name: "fields[inAppPurchases]", value: "submitWithNextAppStoreVersion"),
                // Server-side filter — queueing only matters in READY_TO_SUBMIT, so we
                // skip IAPs that are already under review or live.
                URLQueryItem(name: "filter[state]", value: "READY_TO_SUBMIT"),
                URLQueryItem(name: "limit", value: "200"),
            ],
            cookies: session.cookies
        )
        let response = try JSONDecoder().decode(IrisIAPStateResponse.self, from: data)
        var flags: [String: Bool] = [:]
        for item in response.data {
            flags[item.id] = item.attributes?.submitWithNextAppStoreVersion ?? false
        }
        return flags
    }
}

private struct IrisIAPStateResponse: Decodable {
    let data: [Item]

    struct Item: Decodable {
        let id: String
        let attributes: Attributes?
    }

    struct Attributes: Decodable {
        let submitWithNextAppStoreVersion: Bool?
    }
}
