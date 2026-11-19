import Mockable

@Mockable
public protocol VersionLocalizationRepository: Sendable {
    func listLocalizations(versionId: String) async throws -> [AppStoreVersionLocalization]
    func createLocalization(versionId: String, locale: String) async throws -> AppStoreVersionLocalization
    func updateLocalization(
        localizationId: String,
        whatsNew: String?,
        description: String?,
        keywords: String?,
        marketingUrl: String?,
        supportUrl: String?,
        promotionalText: String?
    ) async throws -> AppStoreVersionLocalization
}
