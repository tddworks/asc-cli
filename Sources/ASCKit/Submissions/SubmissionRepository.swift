import Mockable

@Mockable
public protocol SubmissionRepository: Sendable {
    func submitVersion(versionId: String) async throws -> ReviewSubmission
    func listSubmissions(appId: String, states: [ReviewSubmissionState]?, limit: Int?) async throws -> [ReviewSubmission]
    func getSubmission(id: String) async throws -> ReviewSubmission
    func listSubmissionItems(submissionId: String) async throws -> [ReviewSubmissionItem]
    /// Returns the app's open draft for `platform`, creating one when there is none —
    /// Apple allows a single open submission per app and platform.
    func createSubmission(appId: String, platform: AppStorePlatform) async throws -> ReviewSubmission
    func addItem(submissionId: String, target: ReviewItemTarget) async throws -> ReviewSubmissionItem
    func removeItem(itemId: String) async throws
    func submit(submissionId: String) async throws -> ReviewSubmission
}
