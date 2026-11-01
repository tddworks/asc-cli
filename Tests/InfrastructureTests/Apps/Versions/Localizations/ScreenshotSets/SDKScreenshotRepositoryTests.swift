@preconcurrency import AppStoreConnect_Swift_SDK
import Testing
@testable import Infrastructure
@testable import Domain

@Suite
struct SDKScreenshotRepositoryTests {

    // MARK: - deleteScreenshot

    @Test func `should delete the screenshot from App Store Connect`() async throws {
        let stub = StubAPIClient()

        try await SDKScreenshotRepository(client: stub).deleteScreenshot(screenshotId: "shot-1")

        #expect(stub.requests.map { "\($0.method) \($0.path)" } == ["DELETE /v1/appScreenshots/shot-1"])
    }

    @Test func `should delete the screenshot set from App Store Connect`() async throws {
        let stub = StubAPIClient()

        try await SDKScreenshotRepository(client: stub).deleteScreenshotSet(setId: "set-1")

        #expect(stub.requests.map { "\($0.method) \($0.path)" } == ["DELETE /v1/appScreenshotSets/set-1"])
    }

    // MARK: - listScreenshotSets

    @Test func `listScreenshotSets injects localizationId into each set`() async throws {
        let stub = StubAPIClient()
        stub.willReturn(AppScreenshotSetsResponse(
            data: [
                AppScreenshotSet(
                    type: .appScreenshotSets,
                    id: "set-1",
                    attributes: .init(screenshotDisplayType: .appIphone67)
                ),
                AppScreenshotSet(
                    type: .appScreenshotSets,
                    id: "set-2",
                    attributes: .init(screenshotDisplayType: .appIpadPro3gen129)
                ),
            ],
            links: .init(this: "")
        ))

        let repo = SDKScreenshotRepository(client: stub)
        let result = try await repo.listScreenshotSets(localizationId: "loc-99")

        #expect(result.count == 2)
        #expect(result.allSatisfy { $0.localizationId == "loc-99" })
    }

    @Test func `listScreenshotSets injects repo into returned sets`() async throws {
        let stub = StubAPIClient()
        stub.willReturn(AppScreenshotSetsResponse(
            data: [
                AppScreenshotSet(
                    type: .appScreenshotSets,
                    id: "set-1",
                    attributes: .init(screenshotDisplayType: .appIphone67)
                ),
            ],
            links: .init(this: "")
        ))

        let repo = SDKScreenshotRepository(client: stub)
        let result = try await repo.listScreenshotSets(localizationId: "loc-1")

        // A set with repo injected does not throw "requires a repository"
        let screenshots = try await result[0].importScreenshots(entries: [], imageURLs: [:])
        #expect(screenshots.isEmpty)
    }

    @Test func `listScreenshotSets maps screenshotDisplayType from SDK attributes`() async throws {
        let stub = StubAPIClient()
        stub.willReturn(AppScreenshotSetsResponse(
            data: [
                AppScreenshotSet(
                    type: .appScreenshotSets,
                    id: "set-1",
                    attributes: .init(screenshotDisplayType: .appIphone67)
                ),
            ],
            links: .init(this: "")
        ))

        let repo = SDKScreenshotRepository(client: stub)
        let result = try await repo.listScreenshotSets(localizationId: "loc-1")

        #expect(result[0].screenshotDisplayType == .iphone67)
    }

    // MARK: - listScreenshots

    @Test func `listScreenshots injects setId into each screenshot`() async throws {
        let stub = StubAPIClient()
        stub.willReturn(AppScreenshotsResponse(
            data: [
                AppScreenshot(
                    type: .appScreenshots,
                    id: "img-1",
                    attributes: .init(fileSize: 512_000, fileName: "screen1.png")
                ),
                AppScreenshot(
                    type: .appScreenshots,
                    id: "img-2",
                    attributes: .init(fileSize: 1_024_000, fileName: "screen2.png")
                ),
            ],
            links: .init(this: "")
        ))

        let repo = SDKScreenshotRepository(client: stub)
        let result = try await repo.listScreenshots(setId: "set-77")

        #expect(result.count == 2)
        #expect(result.allSatisfy { $0.setId == "set-77" })
    }

    @Test func `listScreenshots maps fileName and fileSize from SDK attributes`() async throws {
        let stub = StubAPIClient()
        stub.willReturn(AppScreenshotsResponse(
            data: [
                AppScreenshot(
                    type: .appScreenshots,
                    id: "img-1",
                    attributes: .init(fileSize: 2_048_000, fileName: "hero.png")
                ),
            ],
            links: .init(this: "")
        ))

        let repo = SDKScreenshotRepository(client: stub)
        let result = try await repo.listScreenshots(setId: "set-1")

        #expect(result[0].id == "img-1")
        #expect(result[0].fileName == "hero.png")
        #expect(result[0].fileSize == 2_048_000)
    }
}
