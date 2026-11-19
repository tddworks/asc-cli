import Mockable

@Mockable
public protocol InAppPurchaseOfferCodeRepository: Sendable {
    func listOfferCodes(iapId: String) async throws -> [InAppPurchaseOfferCode]
    /// Creates an offer code with full per-territory pricing.
    ///
    /// `prices` is required at creation time — Apple's `prices` relationship is read-only
    /// once the offer code exists, so callers cannot fix this up later. Pass an empty array
    /// only if you intend to discard the offer code immediately. A `pricePointId` of `nil`
    /// in `OfferCodePriceInput` declares the territory free.
    func createOfferCode(
        iapId: String,
        name: String,
        customerEligibilities: [IAPCustomerEligibility],
        prices: [OfferCodePriceInput]
    ) async throws -> InAppPurchaseOfferCode
    func updateOfferCode(offerCodeId: String, isActive: Bool) async throws -> InAppPurchaseOfferCode

    func listPrices(offerCodeId: String) async throws -> [InAppPurchaseOfferCodePrice]

    func listCustomCodes(offerCodeId: String) async throws -> [InAppPurchaseOfferCodeCustomCode]
    func createCustomCode(
        offerCodeId: String,
        customCode: String,
        numberOfCodes: Int,
        expirationDate: String?
    ) async throws -> InAppPurchaseOfferCodeCustomCode
    func updateCustomCode(customCodeId: String, isActive: Bool) async throws -> InAppPurchaseOfferCodeCustomCode

    func listOneTimeUseCodes(offerCodeId: String) async throws -> [InAppPurchaseOfferCodeOneTimeUseCode]
    func createOneTimeUseCode(
        offerCodeId: String,
        numberOfCodes: Int,
        expirationDate: String,
        environment: OfferCodeEnvironment
    ) async throws -> InAppPurchaseOfferCodeOneTimeUseCode
    func updateOneTimeUseCode(oneTimeCodeId: String, isActive: Bool) async throws -> InAppPurchaseOfferCodeOneTimeUseCode
    func fetchOneTimeUseCodeValues(oneTimeCodeId: String) async throws -> String
}
