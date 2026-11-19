import Mockable

@Mockable
public protocol SubscriptionGroupLocalizationRepository: Sendable {
    func listLocalizations(groupId: String) async throws -> [SubscriptionGroupLocalization]
    func createLocalization(
        groupId: String,
        locale: String,
        name: String,
        customAppName: String?
    ) async throws -> SubscriptionGroupLocalization
    func updateLocalization(
        localizationId: String,
        name: String?,
        customAppName: String?
    ) async throws -> SubscriptionGroupLocalization
    func deleteLocalization(localizationId: String) async throws
}
