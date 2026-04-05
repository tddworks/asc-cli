import Foundation

/// An app bundle from the iris private API.
///
/// Maps to the `appBundles` resource in `/iris/v1/appBundles`.
public struct AppBundle: Sendable, Equatable, Identifiable, Codable {
    public let id: String
    public let name: String
    public let bundleId: String
    public let sku: String
    public let primaryLocale: String
    public let platforms: [String]

    public init(
        id: String,
        name: String,
        bundleId: String,
        sku: String,
        primaryLocale: String,
        platforms: [String]
    ) {
        self.id = id
        self.name = name
        self.bundleId = bundleId
        self.sku = sku
        self.primaryLocale = primaryLocale
        self.platforms = platforms
    }
}

extension AppBundle: Presentable {
    public static var tableHeaders: [String] {
        ["ID", "Name", "Bundle ID", "SKU", "Platforms"]
    }
    public var tableRow: [String] {
        [id, name, bundleId, sku, platforms.joined(separator: ",")]
    }
}

extension AppBundle: AffordanceProviding {
    public var affordances: [String: String] {
        [
            "listVersions": "asc versions list --app-id \(id)",
            "listAppInfos": "asc app-infos list --app-id \(id)",
        ]
    }
}
