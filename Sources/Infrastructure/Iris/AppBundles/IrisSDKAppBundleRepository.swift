import Domain
import Foundation

/// Implements `IrisAppBundleRepository` via the iris private API.
public struct IrisSDKAppBundleRepository: IrisAppBundleRepository, @unchecked Sendable {
    private let client: IrisClient

    public init(client: IrisClient = IrisClient()) {
        self.client = client
    }

    public func listAppBundles(session: IrisSession) async throws -> [AppBundle] {
        let (data, _) = try await client.get(
            path: "appBundles",
            queryItems: [
                URLQueryItem(name: "include", value: "appBundleVersions"),
                URLQueryItem(name: "limit", value: "300"),
            ],
            cookies: session.cookies
        )
        let response = try JSONDecoder().decode(IrisAppBundlesResponse.self, from: data)
        return response.data.map { mapToAppBundle($0) }
    }

    public func createApp(
        session: IrisSession,
        name: String,
        bundleId: String,
        sku: String,
        primaryLocale: String,
        platforms: [String],
        versionString: String
    ) async throws -> AppBundle {
        let request = AppCreateRequest.make(
            name: name,
            bundleId: bundleId,
            sku: sku,
            primaryLocale: primaryLocale,
            platforms: platforms,
            versionString: versionString
        )

        let body = try JSONEncoder().encode(request)
        let (data, _) = try await client.post(
            path: "apps",
            body: body,
            cookies: session.cookies
        )
        let response = try JSONDecoder().decode(IrisSingleAppBundleResponse.self, from: data)
        return mapToAppBundle(response.data, fallbackName: name)
    }

    func mapToAppBundle(_ resource: IrisAppBundleResource, fallbackName: String? = nil) -> AppBundle {
        AppBundle(
            id: resource.id,
            name: resource.attributes.name ?? fallbackName ?? "",
            bundleId: resource.attributes.bundleId ?? "",
            sku: resource.attributes.sku ?? "",
            primaryLocale: resource.attributes.primaryLocale ?? "en-US",
            platforms: resource.attributes.platformNames ?? []
        )
    }
}

// MARK: - Iris JSON:API Response Models

struct IrisAppBundlesResponse: Decodable {
    let data: [IrisAppBundleResource]
}

struct IrisSingleAppBundleResponse: Decodable {
    let data: IrisAppBundleResource
}

struct IrisAppBundleResource: Decodable {
    let id: String
    let type: String
    let attributes: IrisAppBundleAttributes
}

struct IrisAppBundleAttributes: Decodable {
    let name: String?
    let bundleId: String?
    let sku: String?
    let primaryLocale: String?
    let platformNames: [String]?
}
