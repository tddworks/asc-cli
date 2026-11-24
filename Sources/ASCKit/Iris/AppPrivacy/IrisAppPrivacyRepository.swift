import Mockable

/// An app's App Privacy rows and whether they're published, through the iris session
/// (`/iris/v1`). There is no public API.
@Mockable
public protocol IrisAppPrivacyRepository: Sendable {
    /// The label as the App Privacy page shows it: the rows, joined, and whether it's published.
    func fetchPrivacy(session: IrisSession, appId: String) async throws -> AppPrivacy
    /// Every row Apple holds for the app, with the ids a change deletes them by.
    func listDataUsages(session: IrisSession, appId: String) async throws -> [DataUsage]
    func createDataUsage(session: IrisSession, appId: String, entry: DataUsageEntry) async throws
    func deleteDataUsage(session: IrisSession, dataUsageId: String) async throws
    /// Makes the label live.
    func publish(session: IrisSession, appId: String) async throws
}
