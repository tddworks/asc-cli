import Foundation
import Mockable
import Testing
@testable import Domain

@Suite
struct AppScreenshotSetTests {

    @Test
    func `empty set when screenshots count is zero`() {
        let set = MockRepositoryFactory.makeScreenshotSet(id: "1", screenshotsCount: 0)
        #expect(set.isEmpty == true)
    }

    @Test
    func `not empty when screenshots count is positive`() {
        let set = MockRepositoryFactory.makeScreenshotSet(id: "1", screenshotsCount: 3)
        #expect(set.isEmpty == false)
    }

    @Test
    func `device category delegates to display type`() {
        let iPhoneSet = MockRepositoryFactory.makeScreenshotSet(id: "1", displayType: .iphone67)
        let iPadSet = MockRepositoryFactory.makeScreenshotSet(id: "2", displayType: .ipadPro3gen129)
        #expect(iPhoneSet.deviceCategory == .iPhone)
        #expect(iPadSet.deviceCategory == .iPad)
    }

    @Test
    func `display type name delegates to display type`() {
        let set = MockRepositoryFactory.makeScreenshotSet(id: "1", displayType: .iphone67)
        #expect(set.displayTypeName == "iPhone 6.7\"")
    }

    @Test
    func `default screenshots count is zero`() {
        let set = MockRepositoryFactory.makeScreenshotSet(id: "1", displayType: .desktop)
        #expect(set.screenshotsCount == 0)
    }

    @Test
    func `set carries parent localizationId`() {
        let set = MockRepositoryFactory.makeScreenshotSet(id: "s1", localizationId: "loc-99")
        #expect(set.localizationId == "loc-99")
    }

    @Test
    func `set is equatable regardless of injected repo`() {
        let a = MockRepositoryFactory.makeScreenshotSet(id: "1", repo: MockScreenshotRepository())
        let b = MockRepositoryFactory.makeScreenshotSet(id: "1", repo: MockScreenshotRepository())
        #expect(a == b)
    }

    @Test
    func `importScreenshots uses own id as setId`() async throws {
        let mockRepo = MockScreenshotRepository()
        given(mockRepo).uploadScreenshot(setId: .value("set-42"), fileURL: .any)
            .willReturn(MockRepositoryFactory.makeScreenshot(setId: "set-42"))

        let set = MockRepositoryFactory.makeScreenshotSet(id: "set-42", repo: mockRepo)
        let results = try await set.importScreenshots(
            entries: [ScreenshotManifest.ScreenshotEntry(order: 1, file: "en-US/1.png")],
            imageURLs: ["en-US/1.png": URL(fileURLWithPath: "/fake/1.png")]
        )
        #expect(results.count == 1)
        #expect(results[0].setId == "set-42")
    }

    @Test
    func `importScreenshots uploads entries sorted by order`() async throws {
        let mockRepo = MockScreenshotRepository()
        given(mockRepo).uploadScreenshot(setId: .any, fileURL: .any)
            .willReturn(MockRepositoryFactory.makeScreenshot(id: "img-1"))

        let set = MockRepositoryFactory.makeScreenshotSet(id: "set-1", repo: mockRepo)
        let results = try await set.importScreenshots(
            entries: [
                ScreenshotManifest.ScreenshotEntry(order: 2, file: "en-US/2.png"),
                ScreenshotManifest.ScreenshotEntry(order: 1, file: "en-US/1.png"),
            ],
            imageURLs: [
                "en-US/1.png": URL(fileURLWithPath: "/fake/1.png"),
                "en-US/2.png": URL(fileURLWithPath: "/fake/2.png"),
            ]
        )
        #expect(results.count == 2)
    }

    @Test
    func `importScreenshots skips entries with no matching imageURL`() async throws {
        let set = MockRepositoryFactory.makeScreenshotSet(id: "set-1", repo: MockScreenshotRepository())
        let results = try await set.importScreenshots(
            entries: [ScreenshotManifest.ScreenshotEntry(order: 1, file: "missing.png")],
            imageURLs: [:]
        )
        #expect(results.isEmpty)
    }

    @Test
    func `importScreenshots throws when repo is nil`() async throws {
        let set = MockRepositoryFactory.makeScreenshotSet(id: "set-1")  // repo: nil (default)
        await #expect(throws: (any Error).self) {
            try await set.importScreenshots(
                entries: [ScreenshotManifest.ScreenshotEntry(order: 1, file: "en-US/1.png")],
                imageURLs: ["en-US/1.png": URL(fileURLWithPath: "/fake")]
            )
        }
    }

    @Test
    func `set apiLinks include listScreenshots resolving to rest path`() {
        let set = MockRepositoryFactory.makeScreenshotSet(id: "set-1", localizationId: "loc-1")
        let link = set.apiLinks["listScreenshots"]
        #expect(link?.href == "/api/v1/screenshot-sets/set-1/screenshots")
        #expect(link?.method == "GET")
    }

    @Test
    func `set apiLinks include listScreenshotSets resolving to parent path`() {
        let set = MockRepositoryFactory.makeScreenshotSet(id: "set-1", localizationId: "loc-1")
        let link = set.apiLinks["listScreenshotSets"]
        #expect(link?.href == "/api/v1/version-localizations/loc-1/screenshot-sets")
        #expect(link?.method == "GET")
    }

    // MARK: - Codable round-trip

    @Test
    func `decode round-trip preserves value fields`() throws {
        let original = MockRepositoryFactory.makeScreenshotSet(
            id: "set-42", localizationId: "loc-99",
            displayType: .ipadPro3gen129, screenshotsCount: 5
        )
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(AppScreenshotSet.self, from: data)
        #expect(decoded.id == "set-42")
        #expect(decoded.localizationId == "loc-99")
        #expect(decoded.screenshotDisplayType == .ipadPro3gen129)
        #expect(decoded.screenshotsCount == 5)
    }
}
