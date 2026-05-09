@preconcurrency import AppStoreConnect_Swift_SDK
import Testing
@testable import Domain
@testable import Infrastructure

@Suite
struct SDKBetaAppLocalizationRepositoryTests {

    @Test func `listBetaAppLocalizations injects appId into each localization`() async throws {
        let stub = StubAPIClient()
        stub.willReturn(BetaAppLocalizationsWithoutIncludesResponse(
            data: [
                makeSdkLocalization(id: "bal-1", locale: "en-US", description: "Beta desc", feedbackEmail: "beta@example.com"),
                makeSdkLocalization(id: "bal-2", locale: "fr-FR", description: nil, feedbackEmail: nil),
            ],
            links: .init(this: "")
        ))

        let repo = SDKBetaAppLocalizationRepository(client: stub)
        let locs = try await repo.listBetaAppLocalizations(appId: "app-42")

        #expect(locs.count == 2)
        #expect(locs.allSatisfy { $0.appId == "app-42" })
        #expect(locs[0].locale == "en-US")
        #expect(locs[0].description == "Beta desc")
        #expect(locs[0].feedbackEmail == "beta@example.com")
        #expect(locs[1].locale == "fr-FR")
        #expect(locs[1].description == nil)
    }

    @Test func `getBetaAppLocalization returns model with appId from relationship`() async throws {
        let stub = StubAPIClient()
        stub.willReturn(BetaAppLocalizationResponse(
            data: makeSdkLocalization(
                id: "bal-7",
                locale: "ja",
                description: "ベータ版",
                feedbackEmail: nil,
                marketingUrl: "https://example.jp",
                relationshipAppId: "app-99"
            ),
            links: .init(this: "")
        ))

        let repo = SDKBetaAppLocalizationRepository(client: stub)
        let loc = try await repo.getBetaAppLocalization(localizationId: "bal-7")

        #expect(loc.id == "bal-7")
        #expect(loc.appId == "app-99")
        #expect(loc.locale == "ja")
        #expect(loc.description == "ベータ版")
        #expect(loc.marketingUrl == "https://example.jp")
    }

    @Test func `createBetaAppLocalization carries appId from request`() async throws {
        let stub = StubAPIClient()
        stub.willReturn(BetaAppLocalizationResponse(
            data: makeSdkLocalization(
                id: "bal-new",
                locale: "de-DE",
                description: "Beta-Beschreibung",
                feedbackEmail: "beta@example.de"
            ),
            links: .init(this: "")
        ))

        let repo = SDKBetaAppLocalizationRepository(client: stub)
        let loc = try await repo.createBetaAppLocalization(
            appId: "app-1",
            locale: "de-DE",
            update: BetaAppLocalizationUpdate(
                description: "Beta-Beschreibung",
                feedbackEmail: "beta@example.de"
            )
        )

        #expect(loc.id == "bal-new")
        #expect(loc.appId == "app-1")
        #expect(loc.locale == "de-DE")
        #expect(loc.description == "Beta-Beschreibung")
        #expect(loc.feedbackEmail == "beta@example.de")
    }

    @Test func `updateBetaAppLocalization preserves appId from response relationship`() async throws {
        let stub = StubAPIClient()
        stub.willReturn(BetaAppLocalizationResponse(
            data: makeSdkLocalization(
                id: "bal-1",
                locale: "en-US",
                description: "Updated description",
                relationshipAppId: "app-55"
            ),
            links: .init(this: "")
        ))

        let repo = SDKBetaAppLocalizationRepository(client: stub)
        let loc = try await repo.updateBetaAppLocalization(
            localizationId: "bal-1",
            update: BetaAppLocalizationUpdate(description: "Updated description")
        )

        #expect(loc.id == "bal-1")
        #expect(loc.appId == "app-55")
        #expect(loc.description == "Updated description")
    }

    @Test func `deleteBetaAppLocalization completes without throwing`() async throws {
        let stub = StubAPIClient()
        let repo = SDKBetaAppLocalizationRepository(client: stub)
        try await repo.deleteBetaAppLocalization(localizationId: "bal-1")
        #expect(stub.voidRequestCalled)
    }

    // MARK: - Helpers

    private func makeSdkLocalization(
        id: String,
        locale: String,
        description: String?,
        feedbackEmail: String? = nil,
        marketingUrl: String? = nil,
        privacyPolicyUrl: String? = nil,
        tvOsPrivacyPolicy: String? = nil,
        relationshipAppId: String? = nil
    ) -> AppStoreConnect_Swift_SDK.BetaAppLocalization {
        let relationships: AppStoreConnect_Swift_SDK.BetaAppLocalization.Relationships? = relationshipAppId.map {
            .init(app: .init(data: .init(type: .apps, id: $0)))
        }
        return AppStoreConnect_Swift_SDK.BetaAppLocalization(
            type: .betaAppLocalizations,
            id: id,
            attributes: .init(
                feedbackEmail: feedbackEmail,
                marketingURL: marketingUrl,
                privacyPolicyURL: privacyPolicyUrl,
                tvOsPrivacyPolicy: tvOsPrivacyPolicy,
                description: description,
                locale: locale
            ),
            relationships: relationships
        )
    }
}
