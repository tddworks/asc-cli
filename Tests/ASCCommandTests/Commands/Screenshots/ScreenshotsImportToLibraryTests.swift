import ArgumentParser
import Foundation
import Mockable
import Testing
@testable import ASCCommand
@testable import Domain

@Suite
struct ScreenshotsImportToLibraryTests {

    // MARK: - App Store Connect, stubbed to apply what it's sent

    private struct AppStoreConnect {
        let versionRepo = MockVersionRepository()
        let localizationRepo = MockVersionLocalizationRepository()
        let libraryRepo = MockAssetLibraryRepository()
        let imageRepo = MockLibraryImageRepository()
        let placementRepo = MockAssetPlacementRepository()

        init(
            versionState: AppStoreVersionState = .prepareForSubmission,
            locales: [String] = ["en-US"],
            existing: [AssetPlacement] = []
        ) {
            given(versionRepo).getVersion(id: .any).willProduce { id in
                AppStoreVersion(id: id, appId: "app-1", versionString: "2.0", platform: .iOS, state: versionState)
            }
            given(libraryRepo).getAssetLibrary(appId: .any).willProduce { AppAssetLibrary(id: "lib-1", appId: $0) }
            given(libraryRepo).listPlacementGroups(placementType: .any, feature: .any).willReturn([
                AssetPlacementGroup(
                    id: "IPHONE_DYNAMIC_ISLAND_LARGE_PROFILE", placementType: .appScreenshot, platform: "IPHONE_APP_STORE",
                    displayClass: nil, feature: "APP_STORE_VERSIONS", sizes: ["1290x2796"], maxCount: 10
                ),
            ])
            given(localizationRepo).listLocalizations(versionId: .any).willProduce { versionId in
                locales.map { AppStoreVersionLocalization(id: "loc-\($0)", versionId: versionId, locale: $0) }
            }
            given(localizationRepo).createLocalization(versionId: .any, locale: .any).willProduce { versionId, locale in
                AppStoreVersionLocalization(id: "loc-\(locale)", versionId: versionId, locale: locale)
            }
            given(imageRepo).uploadImage(libraryId: .any, fileURL: .any, category: .any, referenceName: .any).willProduce { libraryId, url, category, _ in
                LibraryImage(
                    id: "img-\(url.deletingPathExtension().lastPathComponent)", libraryId: libraryId,
                    fileName: url.lastPathComponent, fileSize: 1, category: category, state: .prepareForSubmission
                )
            }
            given(placementRepo).listPlacements(surface: .any, localizationId: .any, placementType: .any, placementGroup: .any)
                .willProduce { _, localizationId, _, _ in existing.filter { $0.localizationId == localizationId } }
            given(placementRepo).createPlacement(surface: .any, localizationId: .any, mediaType: .any, assetId: .any, placementType: .any, placementGroup: .any)
                .willProduce { surface, localizationId, mediaType, assetId, placementType, placementGroup in
                    AssetPlacement(
                        id: "pl-\(assetId.dropFirst(4))", surface: surface, localizationId: localizationId, mediaType: mediaType,
                        assetId: assetId, placementType: placementType, placementGroup: placementGroup, state: .assetProcessing
                    )
                }
            given(placementRepo).reorderPlacements(surface: .any, localizationId: .any, placementGroup: .any, placementIds: .any)
                .willProduce { surface, localizationId, placementGroup, placementIds in
                    placementIds.enumerated().map { index, id in
                        AssetPlacement(
                            id: id, surface: surface, localizationId: localizationId, mediaType: .image, assetId: "-",
                            placementType: .appScreenshot, placementGroup: placementGroup, position: index + 1, state: .assetProcessing
                        )
                    }
                }
        }

        func importScreenshots(
            _ args: [String],
            _ localizations: [String: [String]],
            affordanceMode: AffordanceMode = .cli
        ) async throws -> ScreenshotImportReport {
            let cmd = try ScreenshotsImport.parse(["--version-id", "v-1", "--from", "/export.zip", "--to-library", "--pretty"] + args)
            let manifest = ScreenshotManifest(
                version: "1.0", exportedAt: nil,
                localizations: localizations.mapValues { files in
                    ScreenshotManifest.LocalizationManifest(
                        displayType: .iphone67,
                        screenshots: files.enumerated().map { ScreenshotManifest.ScreenshotEntry(order: $0.offset + 1, file: $0.element) }
                    )
                }
            )
            let files = localizations.values.flatMap { $0 }.map {
                ScreenshotImportFile(file: $0, url: URL(fileURLWithPath: "/export/\($0)"), contentHash: "sha-\($0)", width: 1290, height: 2796)
            }
            return try await cmd.executeToLibrary(
                manifest: manifest, files: files,
                versionRepo: versionRepo, localizationRepo: localizationRepo, libraryRepo: libraryRepo,
                imageRepo: imageRepo, placementRepo: placementRepo,
                affordanceMode: affordanceMode, sleep: { _ in }
            )
        }
    }

    // MARK: - Importing

    @Test func `should place each locale's screenshots from the asset library and show where they went`() async throws {
        let report = try await AppStoreConnect().importScreenshots([], ["en-US": ["en-US/1.png"]])

        #expect(report.isSuccess)
        #expect(report.output == Self.placedInEnglish)
    }

    static let placedInEnglish = """
        {
          "data" : [
            {
              "affordances" : {
                "listPlacements" : "asc asset-placements list --localization-id loc-en-US"
              },
              "locale" : "en-US",
              "localizationId" : "loc-en-US",
              "placementGroup" : "IPHONE_DYNAMIC_ISLAND_LARGE_PROFILE",
              "placements" : [
                {
                  "file" : "en-US\\/1.png",
                  "imageId" : "img-1",
                  "placementId" : "pl-1",
                  "position" : 1
                }
              ],
              "status" : "placed"
            }
          ]
        }
        """

    static let existingInEnglish = AssetPlacement(
        id: "pl-old", surface: .appStoreVersionLocalization, localizationId: "loc-en-US", mediaType: .image, assetId: "img-old",
        placementType: .appScreenshot, placementGroup: "IPHONE_DYNAMIC_ISLAND_LARGE_PROFILE", position: 1, state: .parentPrepareForSubmission
    )

    @Test func `should add the locales the version doesn't have yet`() async throws {
        let report = try await AppStoreConnect(locales: []).importScreenshots([], ["fr-FR": ["fr-FR/1.png"]])

        #expect(report.output == """
        {
          "data" : [
            {
              "affordances" : {
                "listPlacements" : "asc asset-placements list --localization-id loc-fr-FR"
              },
              "locale" : "fr-FR",
              "localizationId" : "loc-fr-FR",
              "placementGroup" : "IPHONE_DYNAMIC_ISLAND_LARGE_PROFILE",
              "placements" : [
                {
                  "file" : "fr-FR\\/1.png",
                  "imageId" : "img-1",
                  "placementId" : "pl-1",
                  "position" : 1
                }
              ],
              "status" : "placed"
            }
          ]
        }
        """)
    }

    @Test func `should show the plan without uploading or adding locales on a dry run`() async throws {
        let report = try await AppStoreConnect(locales: []).importScreenshots(["--dry-run"], ["fr-FR": ["fr-FR/1.png"]])

        #expect(report.isSuccess)
        #expect(report.output == """
        {
          "data" : [
            {
              "affordances" : {

              },
              "locale" : "fr-FR",
              "placementGroup" : "IPHONE_DYNAMIC_ISLAND_LARGE_PROFILE",
              "placements" : [
                {
                  "file" : "fr-FR\\/1.png"
                }
              ],
              "status" : "planned"
            }
          ]
        }
        """)
    }

    @Test func `should report a conflict with the screenshots already there and offer to replace them`() async throws {
        let report = try await AppStoreConnect(existing: [Self.existingInEnglish]).importScreenshots([], ["en-US": ["en-US/1.png"]])

        #expect(!report.isSuccess)
        #expect(report.output == """
        {
          "data" : [
            {
              "affordances" : {
                "listPlacements" : "asc asset-placements list --localization-id loc-en-US",
                "replace" : "asc screenshots import --existing replace --from <zip> --to-library --version-id v-1"
              },
              "existingPlacementIds" : [
                "pl-old"
              ],
              "locale" : "en-US",
              "localizationId" : "loc-en-US",
              "message" : "The localization already has 1 screenshots in this group — pass --existing replace or --existing append",
              "placementGroup" : "IPHONE_DYNAMIC_ISLAND_LARGE_PROFILE",
              "placements" : [
                {
                  "file" : "en-US\\/1.png"
                }
              ],
              "status" : "conflict"
            }
          ]
        }
        """)
    }

    @Test func `should replace the screenshots already there when asked`() async throws {
        let appStoreConnect = AppStoreConnect(existing: [Self.existingInEnglish])
        given(appStoreConnect.placementRepo).deletePlacement(placementId: .any).willReturn()

        let report = try await appStoreConnect.importScreenshots(["--existing", "replace"], ["en-US": ["en-US/1.png"]])

        #expect(report.output == Self.placedInEnglish)
    }

    @Test func `should refuse to import into a version that's no longer editable`() async throws {
        let error = await #expect(throws: ValidationError.self) {
            _ = try await AppStoreConnect(versionState: .readyForSale).importScreenshots([], ["en-US": ["en-US/1.png"]])
        }
        #expect(error?.message == "Version 2.0 is READY_FOR_SALE — screenshots can only change while the version is editable")
    }

    @Test func `should refuse library-only options without --to-library`() {
        #expect(throws: (any Error).self) {
            _ = try ScreenshotsImport.parse(["--version-id", "v-1", "--from", "/export.zip", "--dry-run"])
        }
    }

    // MARK: - REST

    @Test func `should link a REST client to the localization's placements and the replace endpoint`() async throws {
        let report = try await AppStoreConnect(existing: [Self.existingInEnglish])
            .importScreenshots([], ["en-US": ["en-US/1.png"]], affordanceMode: .rest)

        #expect(report.output == """
        {
          "data" : [
            {
              "_links" : {
                "listPlacements" : {
                  "href" : "\\/api\\/v1\\/version-localizations\\/loc-en-US\\/placements",
                  "method" : "GET"
                },
                "replace" : {
                  "href" : "\\/api\\/v1\\/versions\\/v-1\\/screenshots\\/import",
                  "method" : "POST"
                }
              },
              "existingPlacementIds" : [
                "pl-old"
              ],
              "locale" : "en-US",
              "localizationId" : "loc-en-US",
              "message" : "The localization already has 1 screenshots in this group — pass --existing replace or --existing append",
              "placementGroup" : "IPHONE_DYNAMIC_ISLAND_LARGE_PROFILE",
              "placements" : [
                {
                  "file" : "en-US\\/1.png"
                }
              ],
              "status" : "conflict"
            }
          ]
        }
        """)
    }

    @Test func `should take the same options over REST as on the command line`() throws {
        let cmd = try ScreenshotImportController.command(versionId: "v-1", zipPath: "/tmp/upload.zip", query: [
            ("to-library", "true"), ("existing", "append"), ("dry-run", "true"),
            ("placement-group", "IPAD_129_PROFILE"), ("placement-group", "TV_PROFILE"),
        ])

        #expect(cmd.versionId == "v-1")
        #expect(cmd.from == "/tmp/upload.zip")
        #expect(cmd.toLibrary)
        #expect(cmd.existing == .append)
        #expect(cmd.dryRun)
        #expect(cmd.placementGroup == ["IPAD_129_PROFILE", "TV_PROFILE"])
    }

    @Test func `should refuse a REST import that isn't into the asset library`() {
        #expect(throws: (any Error).self) {
            _ = try ScreenshotImportController.command(versionId: "v-1", zipPath: "/tmp/upload.zip", query: [])
        }
    }
}
