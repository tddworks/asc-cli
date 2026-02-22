@preconcurrency import AppStoreConnect_Swift_SDK
import Testing
@testable import Infrastructure
@testable import Domain

@Suite
struct SDKScreenshotRepositoryCreateTests {

    // MARK: - createLocalization

    @Test func `createLocalization injects versionId into response`() async throws {
        let stub = StubAPIClient()
        stub.willReturn(AppStoreVersionLocalizationResponse(
            data: AppStoreVersionLocalization(
                type: .appStoreVersionLocalizations,
                id: "loc-new",
                attributes: .init(locale: "en-US")
            ),
            links: .init(this: "")
        ))

        let repo = SDKScreenshotRepository(client: stub)
        let result = try await repo.createLocalization(versionId: "v-42", locale: "en-US")

        #expect(result.id == "loc-new")
        #expect(result.versionId == "v-42")
        #expect(result.locale == "en-US")
    }

    // MARK: - createScreenshotSet

    @Test func `createScreenshotSet injects localizationId into response`() async throws {
        let stub = StubAPIClient()
        stub.willReturn(AppScreenshotSetResponse(
            data: AppScreenshotSet(
                type: .appScreenshotSets,
                id: "set-new",
                attributes: .init(screenshotDisplayType: .appIphone67)
            ),
            links: .init(this: "")
        ))

        let repo = SDKScreenshotRepository(client: stub)
        let result = try await repo.createScreenshotSet(localizationId: "loc-42", displayType: .iphone67)

        #expect(result.id == "set-new")
        #expect(result.localizationId == "loc-42")
        #expect(result.screenshotDisplayType == .iphone67)
    }

    @Test func `createScreenshotSet maps display type from SDK response`() async throws {
        let stub = StubAPIClient()
        stub.willReturn(AppScreenshotSetResponse(
            data: AppScreenshotSet(
                type: .appScreenshotSets,
                id: "set-1",
                attributes: .init(screenshotDisplayType: .appIpadPro3gen11)
            ),
            links: .init(this: "")
        ))

        let repo = SDKScreenshotRepository(client: stub)
        let result = try await repo.createScreenshotSet(localizationId: "loc-1", displayType: .ipadPro3gen11)

        #expect(result.screenshotDisplayType == .ipadPro3gen11)
    }
}
