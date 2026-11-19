import Mockable

@Mockable
public protocol AppWallRepository: Sendable {
    /// Forks the upstream repo, adds `app` to `homepage/apps.json`, and opens a pull request.
    /// - Returns: The created pull request details.
    func submit(app: AppWallApp) async throws -> AppWallSubmission
}
