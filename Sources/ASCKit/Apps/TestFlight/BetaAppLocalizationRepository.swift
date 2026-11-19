import Mockable

@Mockable
public protocol BetaAppLocalizationRepository: Sendable {
    func listBetaAppLocalizations(appId: String) async throws -> [BetaAppLocalization]
    func getBetaAppLocalization(localizationId: String) async throws -> BetaAppLocalization
    func createBetaAppLocalization(
        appId: String,
        locale: String,
        update: BetaAppLocalizationUpdate
    ) async throws -> BetaAppLocalization
    func updateBetaAppLocalization(
        localizationId: String,
        update: BetaAppLocalizationUpdate
    ) async throws -> BetaAppLocalization
    func deleteBetaAppLocalization(localizationId: String) async throws
}
