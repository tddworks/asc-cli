import Mockable

@Mockable
public protocol PromotedPurchaseRepository: Sendable {
    func listPromotedPurchases(appId: String, limit: Int?) async throws -> PaginatedResponse<PromotedPurchase>
    func createPromotedPurchase(
        appId: String,
        isVisibleForAllUsers: Bool,
        isEnabled: Bool?,
        inAppPurchaseId: String?,
        subscriptionId: String?
    ) async throws -> PromotedPurchase
    func updatePromotedPurchase(
        promotedId: String,
        isVisibleForAllUsers: Bool?,
        isEnabled: Bool?
    ) async throws -> PromotedPurchase
    func deletePromotedPurchase(promotedId: String) async throws
}
