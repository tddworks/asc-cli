import Mockable

@Mockable
public protocol SubscriptionOfferCodeRepository: Sendable {
    func listOfferCodes(subscriptionId: String) async throws -> [SubscriptionOfferCode]
    /// Creates a subscription offer code.
    ///
    /// `isAutoRenewEnabled = false` declares a non-renewing (one-time) offer; Apple
    /// only accepts `freeTrial` mode for those, so callers should constrain `offerMode`
    /// accordingly. `prices` is required at creation time — `prices` is read-only after
    /// creation. A `pricePointId` of `nil` in `OfferCodePriceInput` declares the territory free.
    func createOfferCode(
        subscriptionId: String,
        name: String,
        customerEligibilities: [SubscriptionCustomerEligibility],
        offerEligibility: SubscriptionOfferEligibility,
        duration: SubscriptionOfferDuration,
        offerMode: SubscriptionOfferMode,
        numberOfPeriods: Int,
        isAutoRenewEnabled: Bool,
        prices: [OfferCodePriceInput]
    ) async throws -> SubscriptionOfferCode
    func updateOfferCode(offerCodeId: String, isActive: Bool) async throws -> SubscriptionOfferCode

    func listPrices(offerCodeId: String) async throws -> [SubscriptionOfferCodePrice]

    func listCustomCodes(offerCodeId: String) async throws -> [SubscriptionOfferCodeCustomCode]
    func createCustomCode(
        offerCodeId: String,
        customCode: String,
        numberOfCodes: Int,
        expirationDate: String?
    ) async throws -> SubscriptionOfferCodeCustomCode
    func updateCustomCode(customCodeId: String, isActive: Bool) async throws -> SubscriptionOfferCodeCustomCode

    func listOneTimeUseCodes(offerCodeId: String) async throws -> [SubscriptionOfferCodeOneTimeUseCode]
    func createOneTimeUseCode(
        offerCodeId: String,
        numberOfCodes: Int,
        expirationDate: String,
        environment: OfferCodeEnvironment
    ) async throws -> SubscriptionOfferCodeOneTimeUseCode
    func updateOneTimeUseCode(oneTimeCodeId: String, isActive: Bool) async throws -> SubscriptionOfferCodeOneTimeUseCode
    func fetchOneTimeUseCodeValues(oneTimeCodeId: String) async throws -> String
}
