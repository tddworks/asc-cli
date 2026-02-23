import Mockable

@Mockable
public protocol AppInfoRepository: Sendable {
    func listAppInfos(appId: String) async throws -> [AppInfo]
    func listLocalizations(appInfoId: String) async throws -> [AppInfoLocalization]
    func createLocalization(appInfoId: String, locale: String, name: String) async throws -> AppInfoLocalization
    func updateLocalization(id: String, name: String?, subtitle: String?, privacyPolicyUrl: String?) async throws -> AppInfoLocalization
}
