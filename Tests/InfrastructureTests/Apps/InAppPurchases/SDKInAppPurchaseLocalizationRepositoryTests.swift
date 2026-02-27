@preconcurrency import AppStoreConnect_Swift_SDK
import Testing
@testable import Infrastructure
@testable import Domain

@Suite
struct SDKInAppPurchaseLocalizationRepositoryTests {

    // MARK: - listLocalizations

    @Test func `listLocalizations injects iapId into each localization`() async throws {
        let stub = StubAPIClient()
        stub.willReturn(InAppPurchaseLocalizationsResponse(
            data: [
                InAppPurchaseLocalization(type: .inAppPurchaseLocalizations, id: "loc-1", attributes: .init(name: "Gold Coins", locale: "en-US")),
                InAppPurchaseLocalization(type: .inAppPurchaseLocalizations, id: "loc-2", attributes: .init(name: "金币", locale: "zh-Hans")),
            ],
            links: .init(this: "")
        ))

        let repo = SDKInAppPurchaseLocalizationRepository(client: stub)
        let result = try await repo.listLocalizations(iapId: "iap-42")

        #expect(result.count == 2)
        #expect(result.allSatisfy { $0.iapId == "iap-42" })
    }

    @Test func `listLocalizations maps locale and name from SDK attributes`() async throws {
        let stub = StubAPIClient()
        stub.willReturn(InAppPurchaseLocalizationsResponse(
            data: [
                InAppPurchaseLocalization(
                    type: .inAppPurchaseLocalizations,
                    id: "loc-1",
                    attributes: .init(name: "Pièces d'or", locale: "fr-FR", description: "Monnaie du jeu")
                ),
            ],
            links: .init(this: "")
        ))

        let repo = SDKInAppPurchaseLocalizationRepository(client: stub)
        let result = try await repo.listLocalizations(iapId: "iap-1")

        #expect(result[0].locale == "fr-FR")
        #expect(result[0].name == "Pièces d'or")
        #expect(result[0].description == "Monnaie du jeu")
    }

    @Test func `listLocalizations maps id from SDK response`() async throws {
        let stub = StubAPIClient()
        stub.willReturn(InAppPurchaseLocalizationsResponse(
            data: [
                InAppPurchaseLocalization(type: .inAppPurchaseLocalizations, id: "loc-xyz", attributes: .init(locale: "en-US")),
            ],
            links: .init(this: "")
        ))

        let repo = SDKInAppPurchaseLocalizationRepository(client: stub)
        let result = try await repo.listLocalizations(iapId: "iap-1")

        #expect(result[0].id == "loc-xyz")
    }

    // MARK: - createLocalization

    @Test func `createLocalization injects iapId into response`() async throws {
        let stub = StubAPIClient()
        stub.willReturn(InAppPurchaseLocalizationResponse(
            data: InAppPurchaseLocalization(
                type: .inAppPurchaseLocalizations,
                id: "loc-new",
                attributes: .init(name: "Gold Coins", locale: "en-US", description: "In-game currency")
            ),
            links: .init(this: "")
        ))

        let repo = SDKInAppPurchaseLocalizationRepository(client: stub)
        let result = try await repo.createLocalization(
            iapId: "iap-42",
            locale: "en-US",
            name: "Gold Coins",
            description: "In-game currency"
        )

        #expect(result.id == "loc-new")
        #expect(result.iapId == "iap-42")
        #expect(result.locale == "en-US")
        #expect(result.name == "Gold Coins")
        #expect(result.description == "In-game currency")
    }

    @Test func `createLocalization without description sets description to nil`() async throws {
        let stub = StubAPIClient()
        stub.willReturn(InAppPurchaseLocalizationResponse(
            data: InAppPurchaseLocalization(
                type: .inAppPurchaseLocalizations,
                id: "loc-new",
                attributes: .init(name: "金币", locale: "zh-Hans")
            ),
            links: .init(this: "")
        ))

        let repo = SDKInAppPurchaseLocalizationRepository(client: stub)
        let result = try await repo.createLocalization(
            iapId: "iap-1",
            locale: "zh-Hans",
            name: "金币",
            description: nil
        )

        #expect(result.description == nil)
    }
}
