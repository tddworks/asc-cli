import Foundation
import Testing
@testable import Domain

@Suite
struct ScreenshotImportPlanTests {

    // MARK: - Reference data

    static let iPhone = MockRepositoryFactory.makeAssetPlacementGroup(
        id: "IPHONE_DYNAMIC_ISLAND_LARGE_PROFILE", sizes: ["1290x2796", "2796x1290"], maxCount: 10
    )
    static let iPad129 = MockRepositoryFactory.makeAssetPlacementGroup(
        id: "IPAD_129_PROFILE", platform: "IPAD_APP_STORE", displayClass: "IPAD_129", sizes: ["2048x2732", "2732x2048"], maxCount: 10
    )
    static let iPad13 = MockRepositoryFactory.makeAssetPlacementGroup(
        id: "IPAD_13_PROFILE", platform: "IPAD_APP_STORE", displayClass: "IPAD_13", sizes: ["2064x2752", "2048x2732", "2732x2048"], maxCount: 10
    )
    static let referenceData = [
        iPhone,
        // The same group again for custom product pages and as a preview slot — neither is a version screenshot slot.
        MockRepositoryFactory.makeAssetPlacementGroup(id: "IPHONE_DYNAMIC_ISLAND_LARGE_PROFILE", feature: "CUSTOM_PRODUCT_PAGES", sizes: ["1290x2796"]),
        MockRepositoryFactory.makeAssetPlacementGroup(id: "IPHONE_67_PREVIEW", placementType: .appPreview, sizes: ["1290x2796"]),
        iPad129,
        iPad13,
    ]

    static let english = MockRepositoryFactory.makeLocalization(id: "loc-en", versionId: "v-1", locale: "en-US")
    static let german = MockRepositoryFactory.makeLocalization(id: "loc-de", versionId: "v-1", locale: "de-DE")

    private func plan(
        _ localizations: [String: [String]],
        files: [ScreenshotImportFile],
        existingLocalizations: [AppStoreVersionLocalization] = [english, german],
        existing: [AssetPlacement] = [],
        overrides: [String] = [],
        policy: ExistingScreenshotsPolicy = .fail,
        groups: [AssetPlacementGroup] = referenceData
    ) -> ScreenshotImportPlan {
        ScreenshotImportPlan.plan(
            manifest: MockRepositoryFactory.makeScreenshotManifest(localizations),
            files: files,
            groups: groups,
            localizations: existingLocalizations,
            existing: existing,
            overrides: overrides,
            policy: policy
        )
    }

    // MARK: - Matching sizes to placement groups

    @Test func `should plan each locale's screenshots into the group whose size they match, in manifest order`() {
        let plan = plan(
            ["en-US": ["en-US/1.png", "en-US/2.png"], "de-DE": ["de-DE/1.png"]],
            files: [
                MockRepositoryFactory.makeScreenshotImportFile(file: "en-US/2.png"),
                MockRepositoryFactory.makeScreenshotImportFile(file: "en-US/1.png"),
                MockRepositoryFactory.makeScreenshotImportFile(file: "de-DE/1.png"),
            ]
        )

        #expect(plan.results == [
            ScreenshotImportGroupResult(
                locale: "de-DE", localizationId: "loc-de", versionId: "v-1", placementGroup: "IPHONE_DYNAMIC_ISLAND_LARGE_PROFILE",
                status: .planned, placements: [ScreenshotImportPlacement(file: "de-DE/1.png")]
            ),
            ScreenshotImportGroupResult(
                locale: "en-US", localizationId: "loc-en", versionId: "v-1", placementGroup: "IPHONE_DYNAMIC_ISLAND_LARGE_PROFILE",
                status: .planned, placements: [ScreenshotImportPlacement(file: "en-US/1.png"), ScreenshotImportPlacement(file: "en-US/2.png")]
            ),
        ])
    }

    @Test func `should split a locale's screenshots across the groups their sizes belong to`() {
        let plan = plan(
            ["en-US": ["en-US/iphone.png", "en-US/ipad.png"]],
            files: [
                MockRepositoryFactory.makeScreenshotImportFile(file: "en-US/iphone.png"),
                MockRepositoryFactory.makeScreenshotImportFile(file: "en-US/ipad.png", width: 2064, height: 2752),
            ]
        )

        #expect(plan.results.map(\.placementGroup) == ["IPHONE_DYNAMIC_ISLAND_LARGE_PROFILE", "IPAD_13_PROFILE"])
        #expect(plan.results.map(\.status) == [.planned, .planned])
    }

    @Test func `should plan a locale the version doesn't have yet without a localization id`() {
        let plan = plan(
            ["fr-FR": ["fr-FR/1.png"]],
            files: [MockRepositoryFactory.makeScreenshotImportFile(file: "fr-FR/1.png")]
        )

        #expect(plan.results == [
            ScreenshotImportGroupResult(
                locale: "fr-FR", localizationId: nil, versionId: nil, placementGroup: "IPHONE_DYNAMIC_ISLAND_LARGE_PROFILE",
                status: .planned, placements: [ScreenshotImportPlacement(file: "fr-FR/1.png")]
            ),
        ])
    }

    @Test func `should ask for a placement group when a size fits several`() {
        let plan = plan(
            ["en-US": ["en-US/ipad.png"]],
            files: [MockRepositoryFactory.makeScreenshotImportFile(file: "en-US/ipad.png", width: 2048, height: 2732)]
        )

        #expect(plan.results == [
            ScreenshotImportGroupResult(
                locale: "en-US", localizationId: "loc-en", versionId: "v-1", placementGroup: nil,
                status: .ambiguous, placements: [ScreenshotImportPlacement(file: "en-US/ipad.png")],
                message: "2048x2732 fits several placement groups — pass --placement-group with one of them",
                candidates: ["IPAD_129_PROFILE", "IPAD_13_PROFILE"]
            ),
        ])
        #expect(plan.uniqueUploads.isEmpty)
    }

    @Test func `should use the placement group the user chose when a size fits several`() {
        let plan = plan(
            ["en-US": ["en-US/ipad.png"]],
            files: [MockRepositoryFactory.makeScreenshotImportFile(file: "en-US/ipad.png", width: 2048, height: 2732)],
            overrides: ["IPAD_129_PROFILE"]
        )

        #expect(plan.results.map(\.placementGroup) == ["IPAD_129_PROFILE"])
        #expect(plan.results.map(\.status) == [.planned])
    }

    @Test func `should still ask when the chosen placement group isn't one the size fits`() {
        let plan = plan(
            ["en-US": ["en-US/ipad.png"]],
            files: [MockRepositoryFactory.makeScreenshotImportFile(file: "en-US/ipad.png", width: 2048, height: 2732)],
            overrides: ["IPHONE_DYNAMIC_ISLAND_LARGE_PROFILE"]
        )

        #expect(plan.results.map(\.status) == [.ambiguous])
    }

    @Test func `should report screenshots no version screenshot slot accepts`() {
        let plan = plan(
            ["en-US": ["en-US/odd.png"]],
            files: [MockRepositoryFactory.makeScreenshotImportFile(file: "en-US/odd.png", width: 100, height: 100)]
        )

        #expect(plan.results == [
            ScreenshotImportGroupResult(
                locale: "en-US", localizationId: "loc-en", versionId: "v-1", placementGroup: nil,
                status: .noMatchingGroup, placements: [ScreenshotImportPlacement(file: "en-US/odd.png")],
                message: "No APP_SCREENSHOT placement group accepts 100x100"
            ),
        ])
    }

    // MARK: - Limits

    @Test func `should refuse a group when the screenshots exceed its limit`() {
        let group = MockRepositoryFactory.makeAssetPlacementGroup(sizes: ["1290x2796"], maxCount: 2)
        let files = (1...3).map { MockRepositoryFactory.makeScreenshotImportFile(file: "en-US/\($0).png") }

        let plan = plan(["en-US": files.map(\.file)], files: files, groups: [group])

        #expect(plan.results.map(\.status) == [.overLimit])
        #expect(plan.results.map(\.message) == ["3 screenshots exceed the group's limit of 2"])
        #expect(plan.uniqueUploads.isEmpty)
    }

    @Test func `should count the screenshots already there towards the limit when appending`() {
        let group = MockRepositoryFactory.makeAssetPlacementGroup(sizes: ["1290x2796"], maxCount: 2)
        let files = (1...2).map { MockRepositoryFactory.makeScreenshotImportFile(file: "en-US/\($0).png") }

        let plan = plan(
            ["en-US": files.map(\.file)], files: files,
            existing: [MockRepositoryFactory.makeAssetPlacement(id: "pl-old", localizationId: "loc-en")],
            policy: .append, groups: [group]
        )

        #expect(plan.results.map(\.status) == [.overLimit])
        #expect(plan.results.map(\.message) == ["3 screenshots exceed the group's limit of 2"])
    }

    // MARK: - Screenshots already placed

    @Test func `should report a conflict with the screenshots already there and offer to replace them`() {
        let plan = plan(
            ["en-US": ["en-US/1.png", "en-US/ipad.png"]],
            files: [
                MockRepositoryFactory.makeScreenshotImportFile(file: "en-US/1.png"),
                MockRepositoryFactory.makeScreenshotImportFile(file: "en-US/ipad.png", width: 2064, height: 2752),
            ],
            existing: [
                MockRepositoryFactory.makeAssetPlacement(id: "pl-old-2", localizationId: "loc-en", position: 2),
                MockRepositoryFactory.makeAssetPlacement(id: "pl-old-1", localizationId: "loc-en", position: 1),
            ]
        )

        #expect(plan.results == [
            ScreenshotImportGroupResult(
                locale: "en-US", localizationId: "loc-en", versionId: "v-1", placementGroup: "IPHONE_DYNAMIC_ISLAND_LARGE_PROFILE",
                status: .conflict, placements: [ScreenshotImportPlacement(file: "en-US/1.png")],
                message: "The localization already has 2 screenshots in this group — pass --existing replace or --existing append",
                existingPlacementIds: ["pl-old-1", "pl-old-2"]
            ),
            ScreenshotImportGroupResult(
                locale: "en-US", localizationId: "loc-en", versionId: "v-1", placementGroup: "IPAD_13_PROFILE",
                status: .planned, placements: [ScreenshotImportPlacement(file: "en-US/ipad.png")]
            ),
        ])
        #expect(plan.uniqueUploads.map(\.file) == ["en-US/ipad.png"])
    }

    @Test func `should plan over the screenshots already there when replacing`() {
        let plan = plan(
            ["en-US": ["en-US/1.png"]],
            files: [MockRepositoryFactory.makeScreenshotImportFile(file: "en-US/1.png")],
            existing: [MockRepositoryFactory.makeAssetPlacement(id: "pl-old", localizationId: "loc-en")],
            policy: .replace
        )

        #expect(plan.results.map(\.status) == [.planned])
    }

    // MARK: - Uploads

    @Test func `should upload a screenshot shared by several locales once`() {
        let plan = plan(
            ["en-US": ["en-US/1.png"], "de-DE": ["de-DE/1.png"]],
            files: [
                MockRepositoryFactory.makeScreenshotImportFile(file: "en-US/1.png", contentHash: "same"),
                MockRepositoryFactory.makeScreenshotImportFile(file: "de-DE/1.png", contentHash: "same"),
            ]
        )

        #expect(plan.uniqueUploads.map(\.contentHash) == ["same"])
        #expect(plan.results.map(\.status) == [.planned, .planned])
    }
}
