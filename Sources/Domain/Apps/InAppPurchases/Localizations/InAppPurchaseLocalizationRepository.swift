import Mockable

@Mockable
public protocol InAppPurchaseLocalizationRepository: Sendable {
    func listLocalizations(iapId: String) async throws -> [InAppPurchaseLocalization]
    func createLocalization(
        iapId: String,
        locale: String,
        name: String,
        description: String?
    ) async throws -> InAppPurchaseLocalization
    func updateLocalization(
        localizationId: String,
        name: String?,
        description: String?
    ) async throws -> InAppPurchaseLocalization
    func deleteLocalization(localizationId: String) async throws
}
