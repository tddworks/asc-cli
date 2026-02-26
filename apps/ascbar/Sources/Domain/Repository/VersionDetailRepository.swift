#if MOCKING
@_exported import Mockable
#endif

/// Repository for version detail operations — readiness checks and localization editing.
#if MOCKING
@Mockable
#endif
public protocol VersionDetailRepository: Sendable {
    func fetchReadiness(versionId: String) async throws -> VersionReadinessResult
    func fetchLocalizations(versionId: String) async throws -> [LocalizationSummary]
    func updateWhatsNew(localizationId: String, text: String) async throws
}
