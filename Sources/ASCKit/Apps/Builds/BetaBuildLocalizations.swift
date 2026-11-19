import Mockable

@Mockable
public protocol BetaBuildLocalizations: Sendable {
    func listBetaBuildLocalizations(buildId: String) async throws -> [BetaBuildLocalization]
    func upsertBetaBuildLocalization(buildId: String, locale: String, whatsNew: String) async throws -> BetaBuildLocalization
}
