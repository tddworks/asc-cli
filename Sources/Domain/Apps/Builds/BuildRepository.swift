import Mockable

@Mockable
public protocol BuildRepository: Sendable {
    func listBuilds(appId: String?, platform: BuildUploadPlatform?, version: String?, limit: Int?) async throws -> PaginatedResponse<Build>
    func getBuild(id: String) async throws -> Build
    func addBetaGroups(buildId: String, betaGroupIds: [String]) async throws
    func removeBetaGroups(buildId: String, betaGroupIds: [String]) async throws
    /// Set Apple's export-compliance answer (Info.plist `ITSAppUsesNonExemptEncryption`)
    /// on a previously uploaded build. Required before TestFlight external testing.
    func updateBuildEncryptionCompliance(buildId: String, usesNonExemptEncryption: Bool) async throws -> Build
}
