/// Environment for offer code one-time-use code batches.
///
/// Apple separates offer code redemption into two environments: production codes
/// redeem against live App Store accounts; sandbox codes redeem against sandbox
/// tester accounts and are subject to a smaller per-quarter ceiling. Used by both
/// IAP and subscription one-time-use codes.
public enum OfferCodeEnvironment: String, Sendable, Codable, Equatable {
    case production = "PRODUCTION"
    case sandbox = "SANDBOX"
}
