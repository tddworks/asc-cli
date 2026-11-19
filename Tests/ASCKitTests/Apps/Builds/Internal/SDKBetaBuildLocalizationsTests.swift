@preconcurrency import AppStoreConnect_Swift_SDK
import Testing
@testable import ASCKit

@Suite
struct SDKBetaBuildLocalizationsTests {

    @Test func `listBetaBuildLocalizations injects buildId into each localization`() async throws {
        let stub = StubAPIClient()
        stub.willReturn(BetaBuildLocalizationsWithoutIncludesResponse(
            data: [makeSdkLocalization(id: "bbl-1", locale: "en-US", whatsNew: "Bug fixes")],
            links: .init(this: "")
        ))

        let repo = SDKBetaBuildLocalizations(client: stub)
        let locs = try await repo.listBetaBuildLocalizations(buildId: "build-42")

        #expect(locs.count == 1)
        #expect(locs[0].buildId == "build-42")
        #expect(locs[0].locale == "en-US")
        #expect(locs[0].whatsNew == "Bug fixes")
    }

    // MARK: - upsertBetaBuildLocalization

    @Test func `upsertBetaBuildLocalization patches existing localization when locale matches`() async throws {
        let stub = SequencedStubAPIClient()
        // Step 1: list returns existing match
        stub.enqueue(BetaBuildLocalizationsWithoutIncludesResponse(
            data: [makeSdkLocalization(id: "bbl-1", locale: "en-US", whatsNew: "Old notes")],
            links: .init(this: "")
        ))
        // Step 2: patch returns updated localization
        stub.enqueue(BetaBuildLocalizationResponse(
            data: makeSdkLocalization(id: "bbl-1", locale: "en-US", whatsNew: "New notes"),
            links: .init(this: "")
        ))

        let repo = SDKBetaBuildLocalizations(client: stub)
        let result = try await repo.upsertBetaBuildLocalization(buildId: "build-42", locale: "en-US", whatsNew: "New notes")

        #expect(result.id == "bbl-1")
        #expect(result.buildId == "build-42")
        #expect(result.locale == "en-US")
        #expect(result.whatsNew == "New notes")
    }

    @Test func `upsertBetaBuildLocalization creates new localization when locale not found`() async throws {
        let stub = SequencedStubAPIClient()
        // Step 1: list returns no matching locale
        stub.enqueue(BetaBuildLocalizationsWithoutIncludesResponse(
            data: [],
            links: .init(this: "")
        ))
        // Step 2: post returns new localization
        stub.enqueue(BetaBuildLocalizationResponse(
            data: makeSdkLocalization(id: "bbl-new", locale: "fr-FR", whatsNew: "Nouvelles fonctionnalités"),
            links: .init(this: "")
        ))

        let repo = SDKBetaBuildLocalizations(client: stub)
        let result = try await repo.upsertBetaBuildLocalization(buildId: "build-42", locale: "fr-FR", whatsNew: "Nouvelles fonctionnalités")

        #expect(result.id == "bbl-new")
        #expect(result.buildId == "build-42")
        #expect(result.locale == "fr-FR")
        #expect(result.whatsNew == "Nouvelles fonctionnalités")
    }

    // MARK: - Helpers

    private func makeSdkLocalization(
        id: String,
        locale: String,
        whatsNew: String?
    ) -> AppStoreConnect_Swift_SDK.BetaBuildLocalization {
        AppStoreConnect_Swift_SDK.BetaBuildLocalization(
            type: .betaBuildLocalizations,
            id: id,
            attributes: .init(whatsNew: whatsNew, locale: locale)
        )
    }
}
