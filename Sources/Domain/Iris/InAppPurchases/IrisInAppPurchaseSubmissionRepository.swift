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
}
