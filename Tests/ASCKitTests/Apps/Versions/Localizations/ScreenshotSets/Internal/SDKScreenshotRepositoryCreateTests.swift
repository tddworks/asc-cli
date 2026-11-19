@preconcurrency import AppStoreConnect_Swift_SDK
import Testing
@testable import ASCKit

@Suite
struct SDKScreenshotRepositoryCreateTests {

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

        let repo = SDKAppScreenshots(client: stub)
        let result = try await repo.createScreenshotSet(localizationId: "loc-42", displayType: .iphone67)

        #expect(result.id == "set-new")
        #expect(result.localizationId == "loc-42")
        #expect(result.screenshotDisplayType == .iphone67)
    }

    @Test func `createScreenshotSet injects repo into returned set`() async throws {
        let stub = StubAPIClient()
        stub.willReturn(AppScreenshotSetResponse(
            data: AppScreenshotSet(
                type: .appScreenshotSets,
                id: "set-new",
                attributes: .init(screenshotDisplayType: .appIphone67)
            ),
            links: .init(this: "")
        ))

        let repo = SDKAppScreenshots(client: stub)
        let result = try await repo.createScreenshotSet(localizationId: "loc-1", displayType: .iphone67)

        // A set with repo injected does not throw "requires a repository"
        let screenshots = try await result.importScreenshots(entries: [], imageURLs: [:])
        #expect(screenshots.isEmpty)
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

        let repo = SDKAppScreenshots(client: stub)
        let result = try await repo.createScreenshotSet(localizationId: "loc-1", displayType: .ipadPro3gen11)

        #expect(result.screenshotDisplayType == .ipadPro3gen11)
    }
}
