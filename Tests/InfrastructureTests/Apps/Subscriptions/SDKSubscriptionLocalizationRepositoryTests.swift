@preconcurrency import AppStoreConnect_Swift_SDK
import Testing
@testable import Infrastructure
@testable import Domain

@Suite
struct SDKSubscriptionLocalizationRepositoryTests {

    // MARK: - listLocalizations

    @Test func `listLocalizations injects subscriptionId into each localization`() async throws {
        let stub = StubAPIClient()
        stub.willReturn(SubscriptionLocalizationsResponse(
            data: [
                AppStoreConnect_Swift_SDK.SubscriptionLocalization(type: .subscriptionLocalizations, id: "loc-1", attributes: .init(name: "Monthly Premium", locale: "en-US")),
                AppStoreConnect_Swift_SDK.SubscriptionLocalization(type: .subscriptionLocalizations, id: "loc-2", attributes: .init(name: "月度高级版", locale: "zh-Hans")),
            ],
            links: .init(this: "")
        ))

        let repo = SDKSubscriptionLocalizationRepository(client: stub)
        let result = try await repo.listLocalizations(subscriptionId: "sub-42")

        #expect(result.count == 2)
        #expect(result.allSatisfy { $0.subscriptionId == "sub-42" })
    }

    @Test func `listLocalizations maps locale and name from SDK attributes`() async throws {
        let stub = StubAPIClient()
        stub.willReturn(SubscriptionLocalizationsResponse(
            data: [
                AppStoreConnect_Swift_SDK.SubscriptionLocalization(
                    type: .subscriptionLocalizations,
                    id: "loc-1",
                    attributes: .init(name: "Monatliches Premium", locale: "de-DE", description: "Voller Zugang")
                ),
            ],
            links: .init(this: "")
        ))

        let repo = SDKSubscriptionLocalizationRepository(client: stub)
        let result = try await repo.listLocalizations(subscriptionId: "sub-1")

        #expect(result[0].locale == "de-DE")
        #expect(result[0].name == "Monatliches Premium")
        #expect(result[0].description == "Voller Zugang")
    }

    @Test func `listLocalizations maps id from SDK response`() async throws {
        let stub = StubAPIClient()
        stub.willReturn(SubscriptionLocalizationsResponse(
            data: [
                AppStoreConnect_Swift_SDK.SubscriptionLocalization(type: .subscriptionLocalizations, id: "loc-xyz", attributes: .init(name: nil, locale: "en-US")),
            ],
            links: .init(this: "")
        ))

        let repo = SDKSubscriptionLocalizationRepository(client: stub)
        let result = try await repo.listLocalizations(subscriptionId: "sub-1")

        #expect(result[0].id == "loc-xyz")
    }

    // MARK: - createLocalization

    @Test func `createLocalization injects subscriptionId into response`() async throws {
        let stub = StubAPIClient()
        stub.willReturn(SubscriptionLocalizationResponse(
            data: AppStoreConnect_Swift_SDK.SubscriptionLocalization(
                type: .subscriptionLocalizations,
                id: "loc-new",
                attributes: .init(name: "Monthly Premium", locale: "en-US", description: "Full access to all features")
            ),
            links: .init(this: "")
        ))

        let repo = SDKSubscriptionLocalizationRepository(client: stub)
        let result = try await repo.createLocalization(
            subscriptionId: "sub-42",
            locale: "en-US",
            name: "Monthly Premium",
            description: "Full access to all features"
        )

        #expect(result.id == "loc-new")
        #expect(result.subscriptionId == "sub-42")
        #expect(result.locale == "en-US")
        #expect(result.name == "Monthly Premium")
        #expect(result.description == "Full access to all features")
    }

    @Test func `createLocalization without description sets description to nil`() async throws {
        let stub = StubAPIClient()
        stub.willReturn(SubscriptionLocalizationResponse(
            data: AppStoreConnect_Swift_SDK.SubscriptionLocalization(
                type: .subscriptionLocalizations,
                id: "loc-new",
                attributes: .init(name: "月度高级版", locale: "zh-Hans")
            ),
            links: .init(this: "")
        ))

        let repo = SDKSubscriptionLocalizationRepository(client: stub)
        let result = try await repo.createLocalization(
            subscriptionId: "sub-1",
            locale: "zh-Hans",
            name: "月度高级版",
            description: nil
        )

        #expect(result.description == nil)
    }
}
