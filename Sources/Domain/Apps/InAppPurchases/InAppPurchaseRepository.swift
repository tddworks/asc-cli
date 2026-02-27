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
}
