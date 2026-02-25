@preconcurrency import AppStoreConnect_Swift_SDK
import Testing
@testable import Domain
@testable import Infrastructure

@Suite
struct SDKBetaBuildLocalizationRepositoryTests {

    @Test func `listBetaBuildLocalizations injects buildId into each localization`() async throws {
        let stub = StubAPIClient()
        stub.willReturn(BetaBuildLocalizationsWithoutIncludesResponse(
            data: [makeSdkLocalization(id: "bbl-1", locale: "en-US", whatsNew: "Bug fixes")],
            links: .init(this: "")
        ))

        let repo = SDKBetaBuildLocalizationRepository(client: stub)
        let locs = try await repo.listBetaBuildLocalizations(buildId: "build-42")

        #expect(locs.count == 1)
        #expect(locs[0].buildId == "build-42")
        #expect(locs[0].locale == "en-US")
        #expect(locs[0].whatsNew == "Bug fixes")
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
