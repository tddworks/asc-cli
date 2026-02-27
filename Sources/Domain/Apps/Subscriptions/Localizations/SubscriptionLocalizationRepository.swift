import Mockable

@Mockable
public protocol SubscriptionLocalizationRepository: Sendable {
    func listLocalizations(subscriptionId: String) async throws -> [SubscriptionLocalization]
    func createLocalization(
        subscriptionId: String,
        locale: String,
        name: String,
        description: String?
    ) async throws -> SubscriptionLocalization
}
