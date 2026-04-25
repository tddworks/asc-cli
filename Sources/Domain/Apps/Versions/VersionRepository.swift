import Mockable

@Mockable
public protocol VersionRepository: Sendable {
    func listVersions(appId: String) async throws -> [AppStoreVersion]
    func getVersion(id: String) async throws -> AppStoreVersion
    func createVersion(appId: String, versionString: String, platform: AppStorePlatform) async throws -> AppStoreVersion
    /// Patch an existing version. Every attribute is optional so the
    /// caller only sends the fields the user actually changed; nil means
    /// "leave alone" rather than "clear". `releaseType` accepts the raw
    /// string ("MANUAL", "AFTER_APPROVAL", "SCHEDULED"), and
    /// `earliestReleaseDate` is an ISO-8601 timestamp.
    func updateVersion(
        id: String,
        versionString: String?,
        copyright: String?,
        releaseType: String?,
        earliestReleaseDate: String?
    ) async throws -> AppStoreVersion
    func setBuild(versionId: String, buildId: String) async throws
}
