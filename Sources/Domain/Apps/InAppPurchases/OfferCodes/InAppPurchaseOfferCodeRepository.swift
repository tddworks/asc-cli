import Mockable

@Mockable
public protocol InAppPurchaseOfferCodeRepository: Sendable {
    func listOfferCodes(iapId: String) async throws -> [InAppPurchaseOfferCode]
    func createOfferCode(
        iapId: String,
        name: String,
        customerEligibilities: [IAPCustomerEligibility]
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
