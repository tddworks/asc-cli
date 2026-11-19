import Mockable

/// Reads iris-only IAP attributes — currently just `submitWithNextAppStoreVersion`,
/// the bit that tells whether an IAP is queued to ride along with the next app
/// version. The public ASC SDK has no path that exposes this field, so the iris
/// listing endpoint is the source of truth.
///
/// Used by `SDKInAppPurchases.listInAppPurchases` as a best-effort enrichment:
/// when iris cookies are available the resulting `InAppPurchase.submitWithNextAppStoreVersion`
/// drives the `removeFromNextVersion` affordance; without iris cookies the field
/// stays `false` and CI scripts using API-key auth keep their existing JSON output.
@Mockable
public protocol IrisInAppPurchaseStates: Sendable {
    /// Returns a map of `iapId → submitWithNextAppStoreVersion`. Filtered server-side
    /// to IAPs in `READY_TO_SUBMIT` (the only state where the queue flag is actionable).
    func fetchSubmitFlags(session: IrisSession, appId: String) async throws -> [String: Bool]
}
