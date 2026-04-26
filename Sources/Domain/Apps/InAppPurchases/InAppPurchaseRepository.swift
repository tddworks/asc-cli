import Mockable

@Mockable
public protocol InAppPurchaseRepository: Sendable {
    func listInAppPurchases(appId: String, limit: Int?) async throws -> PaginatedResponse<InAppPurchase>
    func createInAppPurchase(
        appId: String,
        referenceName: String,
        productId: String,
        type: InAppPurchaseType
    ) async throws -> InAppPurchase
    func updateInAppPurchase(
        iapId: String,
        referenceName: String?,
        reviewNote: String?,
        isFamilySharable: Bool?
    ) async throws -> InAppPurchase
    func deleteInAppPurchase(iapId: String) async throws
}
