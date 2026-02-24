import Foundation
import Mockable
import Testing
@testable import ASCCommand
@testable import Domain

@Suite
struct ScreenshotsImportTests {

    // MARK: - Test-context helpers (non-domain types — kept local)

    private func makeManifest(
        locale: String = "en-US",
        displayType: ScreenshotDisplayType = .iphone67,
        files: [String] = ["en-US/1.png"]
    ) -> ScreenshotManifest {
        ScreenshotManifest(
            version: "1.0",
            exportedAt: nil,
            localizations: [
                locale: ScreenshotManifest.LocalizationManifest(
                    displayType: displayType,
                    screenshots: files.enumerated().map { i, file in
                        ScreenshotManifest.ScreenshotEntry(order: i + 1, file: file)
                    }
                )
            ]
        )
    }

    private func makeImageURLs(_ files: [String]) -> [String: URL] {
        Dictionary(uniqueKeysWithValues: files.map { ($0, URL(fileURLWithPath: "/fake/\($0)")) })
    }

    // MARK: - Output format

    @Test func `import uploads screenshots and returns results`() async throws {
        let mockLocRepo = MockVersionLocalizationRepository()
        let mockSsRepo = MockScreenshotRepository()
        given(mockLocRepo).listLocalizations(versionId: .any).willReturn([
            AppStoreVersionLocalization(id: "loc-1", versionId: "v1", locale: "en-US"),
        ])
        given(mockSsRepo).listScreenshotSets(localizationId: .any).willReturn([
            AppScreenshotSet(id: "set-1", localizationId: "loc-1", screenshotDisplayType: .iphone67, repo: mockSsRepo),
        ])
        given(mockSsRepo).uploadScreenshot(setId: .any, fileURL: .any).willReturn(
            AppScreenshot(id: "img-1", setId: "set-1", fileName: "1.png", fileSize: 1_048_576)
        )

        let cmd = try ScreenshotsImport.parse(["--version-id", "v1", "--from", "/fake.zip", "--pretty"])
        let output = try await cmd.execute(
            localizationRepo: mockLocRepo,
            screenshotRepo: mockSsRepo,
            manifest: makeManifest(),
            imageURLs: makeImageURLs(["en-US/1.png"])
        )

        #expect(output == """
        {
          "data" : [
            {
              "affordances" : {
                "listScreenshots" : "asc screenshots list --set-id set-1"
              },
              "fileName" : "1.png",
              "fileSize" : 1048576,
              "id" : "img-1",
              "setId" : "set-1"
            }
          ]
        }
        """)
    }

    // MARK: - Find-or-create localization

    @Test func `import reuses existing localization when locale matches`() async throws {
        let mockLocRepo = MockVersionLocalizationRepository()
        let mockSsRepo = MockScreenshotRepository()
        given(mockLocRepo).listLocalizations(versionId: .any).willReturn([
            AppStoreVersionLocalization(id: "loc-existing", versionId: "v1", locale: "en-US"),
        ])
        given(mockSsRepo).listScreenshotSets(localizationId: .value("loc-existing")).willReturn([
            AppScreenshotSet(id: "set-1", localizationId: "loc-existing", screenshotDisplayType: .iphone67, repo: mockSsRepo),
        ])
        given(mockSsRepo).uploadScreenshot(setId: .any, fileURL: .any).willReturn(
            AppScreenshot(id: "img-1", setId: "set-1", fileName: "1.png", fileSize: 1_048_576)
        )

        let cmd = try ScreenshotsImport.parse(["--version-id", "v1", "--from", "/fake.zip", "--pretty"])
        let output = try await cmd.execute(
            localizationRepo: mockLocRepo,
            screenshotRepo: mockSsRepo,
            manifest: makeManifest(locale: "en-US"),
            imageURLs: makeImageURLs(["en-US/1.png"])
        )

        // createLocalization not mocked — would throw if called, proving reuse
        #expect(output.isEmpty == false)
    }

    @Test func `import creates localization when locale is not found`() async throws {
        let mockLocRepo = MockVersionLocalizationRepository()
        let mockSsRepo = MockScreenshotRepository()
        given(mockLocRepo).listLocalizations(versionId: .any).willReturn([])
        given(mockLocRepo).createLocalization(versionId: .any, locale: .any)
            .willReturn(AppStoreVersionLocalization(id: "loc-new", versionId: "v1", locale: "ja"))
        given(mockSsRepo).listScreenshotSets(localizationId: .any).willReturn([
            AppScreenshotSet(id: "set-1", localizationId: "loc-new", screenshotDisplayType: .iphone67, repo: mockSsRepo),
        ])
        given(mockSsRepo).uploadScreenshot(setId: .any, fileURL: .any).willReturn(
            AppScreenshot(id: "img-1", setId: "set-1", fileName: "1.png", fileSize: 1_048_576)
        )

        let cmd = try ScreenshotsImport.parse(["--version-id", "v1", "--from", "/fake.zip", "--pretty"])
        let output = try await cmd.execute(
            localizationRepo: mockLocRepo,
            screenshotRepo: mockSsRepo,
            manifest: makeManifest(locale: "ja", files: ["ja/1.png"]),
            imageURLs: makeImageURLs(["ja/1.png"])
        )

        // Upload succeeded after creating missing localization
        #expect(output.isEmpty == false)
    }

    // MARK: - Find-or-create screenshot set

    @Test func `import reuses existing screenshot set when display type matches`() async throws {
        let mockLocRepo = MockVersionLocalizationRepository()
        let mockSsRepo = MockScreenshotRepository()
        given(mockLocRepo).listLocalizations(versionId: .any).willReturn([
            AppStoreVersionLocalization(id: "loc-1", versionId: "v1", locale: "en-US"),
        ])
        given(mockSsRepo).listScreenshotSets(localizationId: .any).willReturn([
            AppScreenshotSet(id: "set-existing", localizationId: "loc-1", screenshotDisplayType: .iphone67, repo: mockSsRepo),
        ])
        given(mockSsRepo).uploadScreenshot(setId: .any, fileURL: .any).willReturn(
            AppScreenshot(id: "img-1", setId: "set-existing", fileName: "1.png", fileSize: 1_048_576)
        )

        let cmd = try ScreenshotsImport.parse(["--version-id", "v1", "--from", "/fake.zip", "--pretty"])
        let output = try await cmd.execute(
            localizationRepo: mockLocRepo,
            screenshotRepo: mockSsRepo,
            manifest: makeManifest(displayType: .iphone67),
            imageURLs: makeImageURLs(["en-US/1.png"])
        )

        // createScreenshotSet not mocked — would throw if called, proving reuse
        #expect(output.isEmpty == false)
    }

    @Test func `import creates screenshot set when display type is not found`() async throws {
        let mockLocRepo = MockVersionLocalizationRepository()
        let mockSsRepo = MockScreenshotRepository()
        given(mockLocRepo).listLocalizations(versionId: .any).willReturn([
            AppStoreVersionLocalization(id: "loc-1", versionId: "v1", locale: "en-US"),
        ])
        given(mockSsRepo).listScreenshotSets(localizationId: .any).willReturn([])
        given(mockSsRepo).createScreenshotSet(localizationId: .any, displayType: .any)
            .willReturn(AppScreenshotSet(id: "set-new", localizationId: "loc-1", screenshotDisplayType: .iphone67, repo: mockSsRepo))
        given(mockSsRepo).uploadScreenshot(setId: .any, fileURL: .any).willReturn(
            AppScreenshot(id: "img-1", setId: "set-new", fileName: "1.png", fileSize: 1_048_576)
        )

        let cmd = try ScreenshotsImport.parse(["--version-id", "v1", "--from", "/fake.zip", "--pretty"])
        let output = try await cmd.execute(
            localizationRepo: mockLocRepo,
            screenshotRepo: mockSsRepo,
            manifest: makeManifest(displayType: .iphone67),
            imageURLs: makeImageURLs(["en-US/1.png"])
        )

        // Upload succeeded after creating missing screenshot set
        #expect(output.isEmpty == false)
    }
}
