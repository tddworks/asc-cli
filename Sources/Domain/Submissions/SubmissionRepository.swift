import Mockable

@Mockable
public protocol SubmissionRepository: Sendable {
    func submitVersion(versionId: String) async throws -> ReviewSubmission
    func listSubmissions(appId: String, states: [ReviewSubmissionState]?, limit: Int?) async throws -> [ReviewSubmission]
    func getSubmission(id: String) async throws -> ReviewSubmission
    func listSubmissionItems(submissionId: String) async throws -> [ReviewSubmissionItem]
}
