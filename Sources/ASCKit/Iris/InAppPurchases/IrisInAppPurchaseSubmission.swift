/// A submission record returned by the iris private API.
///
/// Maps to the `inAppPurchaseSubmissions` resource at `POST /iris/v1/inAppPurchaseSubmissions`,
/// which is the only path that accepts `attributes.submitWithNextAppStoreVersion`.
/// The public ASC SDK lacks this knob, so first-time IAP submissions go through this iris
/// flow; subsequent submissions can use either path.
public struct IrisInAppPurchaseSubmission: Sendable, Equatable, Identifiable, Codable {
    public let id: String
    /// Parent IAP — Apple's response omits it; Infrastructure injects from the request.
    public let iapId: String
    /// Whether the submission is bound to the next App Store version (the bit that
    /// makes this iris path materially different from the public SDK path).
    public let submitWithNextAppStoreVersion: Bool

    public init(id: String, iapId: String, submitWithNextAppStoreVersion: Bool) {
        self.id = id
        self.iapId = iapId
        self.submitWithNextAppStoreVersion = submitWithNextAppStoreVersion
    }
}

extension IrisInAppPurchaseSubmission: AffordanceProviding {
    public var structuredAffordances: [Affordance] {
        [
            Affordance(key: "viewIAP", command: "iap", action: "get",
                       params: ["iap-id": iapId]),
        ]
    }
}

extension IrisInAppPurchaseSubmission: Presentable {
    public static var tableHeaders: [String] { ["ID", "IAP ID", "With Next Version"] }
    public var tableRow: [String] { [id, iapId, submitWithNextAppStoreVersion ? "true" : "false"] }
}
