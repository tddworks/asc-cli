import Mockable

@Mockable
public protocol VersionRepository: Sendable {
    func listVersions(appId: String) async throws -> [AppStoreVersion]
    func getVersion(id: String) async throws -> AppStoreVersion
    func createVersion(appId: String, versionString: String, platform: AppStorePlatform) async throws -> AppStoreVersion
    func updateVersion(id: String, versionString: String) async throws -> AppStoreVersion
    func setBuild(versionId: String, buildId: String) async throws
}
