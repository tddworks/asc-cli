import Mockable

/// Repository for the iris-only IAP submission endpoint.
///
/// Distinct from `InAppPurchaseSubmissionRepository` (public SDK, key-auth) so the two
/// auth surfaces don't tangle: `asc iap submit` keeps zero-iris dependency, while this
/// path is reachable only when iris cookies are available.
@Mockable
public protocol IrisInAppPurchaseSubmissionRepository: Sendable {
    func submitInAppPurchase(
        session: IrisSession,
        iapId: String,
        submitWithNextAppStoreVersion: Bool
    ) async throws -> IrisInAppPurchaseSubmission

    /// Removes a previously-queued iris submission. Iris keys the submission resource
    /// by parent IAP id, so for dequeue the `submissionId` IS the IAP id. The public
    /// SDK delete endpoint doesn't accept iris-queued submissions — they round-trip
    /// only through `DELETE /iris/v1/inAppPurchaseSubmissions/:id` with cookie auth.
    func deleteSubmission(
        session: IrisSession,
        submissionId: String
    ) async throws
}
