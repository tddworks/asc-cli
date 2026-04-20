import Mockable

@Mockable
public protocol SubmissionRepository: Sendable {
    func submitVersion(versionId: String) async throws -> ReviewSubmission
    func listSubmissions(appId: String, states: [ReviewSubmissionState]?, limit: Int?) async throws -> [ReviewSubmission]
}