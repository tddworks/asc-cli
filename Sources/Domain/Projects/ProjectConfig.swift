import Foundation

public struct ProjectConfig: Sendable, Equatable, Codable, AffordanceProviding {
    public let appId: String
    public let appName: String
    public let bundleId: String

    public init(appId: String, appName: String, bundleId: String) {
        self.appId = appId
        self.appName = appName
        self.bundleId = bundleId
    }

    public var affordances: [String: String] {
        [
            "listVersions":   "asc versions list --app-id \(appId)",
            "listBuilds":     "asc builds list --app-id \(appId)",
            "listAppInfos":   "asc app-infos list --app-id \(appId)",
            "checkReadiness": "asc versions check-readiness --version-id <id>",
        ]
    }
}
