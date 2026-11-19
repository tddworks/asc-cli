import Mockable

/// An app's compliance requirements and the declarations that answer them, through
/// the iris session (`ppm/compliancerequirements/v1`). There is no public API.
@Mockable
public protocol IrisComplianceRepository: Sendable {
    /// Every requirement on the app's App Compliance page, answered or not, each with its declaration.
    func listRequirements(session: IrisSession, appId: String) async throws -> [ComplianceRequirement]
    /// Saves `answer` for `requirement` — a first answer, or a change to the one Apple holds —
    /// and answers the requirement as it now stands.
    func declare(session: IrisSession, requirement: ComplianceRequirement, answer: ComplianceAnswer) async throws -> ComplianceRequirement
}
