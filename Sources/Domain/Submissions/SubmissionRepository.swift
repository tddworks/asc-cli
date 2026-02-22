import Mockable

@Mockable
public protocol SubmissionRepository: Sendable {
    func submitVersion(versionId: String) async throws -> ReviewSubmission
}