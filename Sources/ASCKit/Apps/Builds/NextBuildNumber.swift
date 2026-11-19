public struct NextBuildNumber: Sendable, Codable, Equatable {
    public let appId: String
    public let version: String
    public let platform: BuildUploadPlatform
    public let nextBuildNumber: Int

    public init(appId: String, version: String, platform: BuildUploadPlatform, nextBuildNumber: Int) {
        self.appId = appId
        self.version = version
        self.platform = platform
        self.nextBuildNumber = nextBuildNumber
    }

    /// Compute the next build number from a list of existing builds.
    /// Parses buildNumber as integer, finds max, returns max + 1.
    /// Returns 1 if no numeric build numbers found.
    public static func compute(appId: String, version: String, platform: BuildUploadPlatform, builds: [Build]) -> NextBuildNumber {
        let maxNumber = builds
            .compactMap { $0.buildNumber }
            .compactMap { Int($0) }
            .max() ?? 0
        return NextBuildNumber(appId: appId, version: version, platform: platform, nextBuildNumber: maxNumber + 1)
    }
}

extension NextBuildNumber: AffordanceProviding {
    public var affordances: [String: String] {
        let platformCli = platform.rawValue.lowercased()
        return [
            "uploadBuild": "asc builds upload --app-id \(appId) --file <path> --version \(version) --build-number \(nextBuildNumber) --platform \(platformCli)",
            "archiveAndUpload": "asc builds archive --scheme <scheme> --platform \(platformCli) --upload --app-id \(appId) --version \(version) --build-number \(nextBuildNumber)",
        ]
    }
}
