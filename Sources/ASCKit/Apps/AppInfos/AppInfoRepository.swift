import Mockable

@Mockable
public protocol AppInfoRepository: Sendable {
    func listAppInfos(appId: String) async throws -> [AppInfo]
    func listLocalizations(appInfoId: String) async throws -> [AppInfoLocalization]
    func createLocalization(appInfoId: String, locale: String, name: String) async throws -> AppInfoLocalization
    func updateLocalization(id: String, name: String?, subtitle: String?, privacyPolicyUrl: String?, privacyChoicesUrl: String?, privacyPolicyText: String?) async throws -> AppInfoLocalization
    func deleteLocalization(id: String) async throws
    func updateCategories(
        id: String,
        primaryCategoryId: String?,
        primarySubcategoryOneId: String?,
        primarySubcategoryTwoId: String?,
        secondaryCategoryId: String?,
        secondarySubcategoryOneId: String?,
        secondarySubcategoryTwoId: String?
    ) async throws -> AppInfo
}
