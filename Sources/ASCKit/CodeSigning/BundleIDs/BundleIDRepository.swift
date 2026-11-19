import Mockable

@Mockable
public protocol BundleIDRepository: Sendable {
    func listBundleIDs(platform: BundleIDPlatform?, identifier: String?) async throws -> [BundleID]
    func createBundleID(name: String, identifier: String, platform: BundleIDPlatform) async throws -> BundleID
    func deleteBundleID(id: String) async throws
}
