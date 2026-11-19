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

extension IrisComplianceRepository {
    /// The row for `requirementId` on `appId`: a requirement id names the compliance on every
    /// app, so a row is found by both (law 2).
    public func requirement(_ requirementId: String, appId: String, session: IrisSession) async throws -> ComplianceRequirement {
        guard let row = try await listRequirements(session: session, appId: appId).first(where: { $0.id == requirementId }) else {
            throw ComplianceError.requirementNotFound(requirementId: requirementId, appId: appId)
        }
        return row
    }
}
