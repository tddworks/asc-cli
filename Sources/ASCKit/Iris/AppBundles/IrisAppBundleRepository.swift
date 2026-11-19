import Mockable

/// Repository for iris app bundle operations (private API).
@Mockable
public protocol IrisAppBundleRepository: Sendable {
    func listAppBundles(session: IrisSession) async throws -> [AppBundle]
    func createApp(
        session: IrisSession,
        name: String,
        bundleId: String,
        sku: String,
        primaryLocale: String,
        platforms: [String],
        versionString: String
    ) async throws -> AppBundle
}
