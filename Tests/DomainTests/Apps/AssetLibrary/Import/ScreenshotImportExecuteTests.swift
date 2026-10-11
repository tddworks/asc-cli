import Foundation
import Testing
@testable import Domain

@Suite
struct ScreenshotImportExecuteTests {

    static let group = "IPHONE_DYNAMIC_ISLAND_LARGE_PROFILE"
    static let referenceData = [MockRepositoryFactory.makeAssetPlacementGroup(id: group, sizes: ["1290x2796"], maxCount: 10)]
    static let english = MockRepositoryFactory.makeLocalization(id: "loc-en", versionId: "v-1", locale: "en-US")
    static let german = MockRepositoryFactory.makeLocalization(id: "loc-de", versionId: "v-1", locale: "de-DE")

    private func plan(
        _ localizations: [String: [String]],
        files: [ScreenshotImportFile]? = nil,
        existingLocalizations: [AppStoreVersionLocalization] = [english, german],
        existing: [AssetPlacement] = [],
        policy: ExistingScreenshotsPolicy = .fail
    ) -> ScreenshotImportPlan {
        ScreenshotImportPlan.plan(
            manifest: MockRepositoryFactory.makeScreenshotManifest(localizations),
            files: files ?? localizations.values.flatMap { $0 }.map { MockRepositoryFactory.makeScreenshotImportFile(file: $0) },
            groups: Self.referenceData,
            localizations: existingLocalizations,
            existing: existing,
            overrides: [],
            policy: policy
        )
    }

    private func run(_ plan: ScreenshotImportPlan, library: FakeLibrary, placements: FakePlacements) async -> [ScreenshotImportGroupResult] {
        await plan.execute(libraryId: "lib-1", imageRepo: library, placementRepo: placements, sleep: { _ in })
    }

    // MARK: - Placing

    @Test func `should upload, place and order each locale's screenshots in manifest order`() async {
        let library = FakeLibrary()
        let placements = FakePlacements()

        let results = await run(plan(["en-US": ["en-US/1.png", "en-US/2.png"]]), library: library, placements: placements)

        #expect(results == [
            ScreenshotImportGroupResult(
                locale: "en-US", localizationId: "loc-en", versionId: "v-1", placementGroup: Self.group, status: .placed,
                placements: [
                    ScreenshotImportPlacement(file: "en-US/1.png", imageId: "img-1", placementId: "pl-1", position: 1),
                    ScreenshotImportPlacement(file: "en-US/2.png", imageId: "img-2", placementId: "pl-2", position: 2),
                ]
            ),
        ])
        #expect(placements.group("loc-en", Self.group).map(\.assetId) == ["img-1", "img-2"])
    }

    @Test func `should upload a screenshot shared by several locales once and place it in each`() async {
        let library = FakeLibrary()
        let placements = FakePlacements()
        let shared = plan(
            ["en-US": ["en-US/1.png"], "de-DE": ["de-DE/1.png"]],
            files: [
                MockRepositoryFactory.makeScreenshotImportFile(file: "en-US/1.png", contentHash: "same"),
                MockRepositoryFactory.makeScreenshotImportFile(file: "de-DE/1.png", contentHash: "same"),
            ]
        )

        let results = await run(shared, library: library, placements: placements)

        #expect(library.images.count == 1)
        #expect(results.map(\.status) == [.placed, .placed])
        #expect(placements.group("loc-de", Self.group).map(\.assetId) == ["img-1"])
        #expect(placements.group("loc-en", Self.group).map(\.assetId) == ["img-1"])
    }

    @Test func `should wait for App Store Connect to process the screenshots before placing them`() async {
        let library = FakeLibrary(readsUntilProcessed: 3)
        let placements = FakePlacements()

        let results = await run(plan(["en-US": ["en-US/1.png"]]), library: library, placements: placements)

        #expect(results.map(\.status) == [.placed])
        #expect(library.images.map(\.state) == [.prepareForSubmission])
    }

    @Test func `should give up on screenshots App Store Connect is still processing after the wait`() async {
        let library = FakeLibrary(readsUntilProcessed: .max)
        let placements = FakePlacements()

        let results = await run(plan(["en-US": ["en-US/1.png"]]), library: library, placements: placements)

        #expect(results.map(\.status) == [.failed])
        #expect(results.map(\.message) == ["App Store Connect is still processing en-US/1.png — check `asc asset-images list` and place it later"])
        #expect(placements.all.isEmpty)
    }

    @Test func `should fail every group using a screenshot App Store Connect couldn't process and place the rest`() async {
        let library = FakeLibrary(failing: ["broken.png": AssetStateDetail(code: "IMAGE_INCORRECT_DIMENSIONS", description: "Wrong size")])
        let placements = FakePlacements()
        let mixed = plan(
            ["en-US": ["en-US/broken.png"], "de-DE": ["de-DE/1.png"]],
            files: [
                MockRepositoryFactory.makeScreenshotImportFile(file: "en-US/broken.png"),
                MockRepositoryFactory.makeScreenshotImportFile(file: "de-DE/1.png"),
            ]
        )

        let results = await run(mixed, library: library, placements: placements)

        #expect(results.map(\.status) == [.placed, .failed])
        #expect(results.map(\.message) == [nil, "App Store Connect couldn't process en-US/broken.png: IMAGE_INCORRECT_DIMENSIONS Wrong size"])
        #expect(placements.group("loc-en", Self.group).isEmpty)
    }

    @Test func `should report a group App Store Connect refused without stopping the others`() async {
        let library = FakeLibrary()
        let placements = FakePlacements(refusing: "loc-de")

        let results = await run(plan(["en-US": ["en-US/1.png"], "de-DE": ["de-DE/1.png"]]), library: library, placements: placements)

        #expect(results.map(\.status) == [.failed, .placed])
        #expect(results.map(\.message) == ["The localization is locked", nil])
    }

    @Test func `should fail a group whose locale the version doesn't have`() async {
        let results = await run(
            plan(["fr-FR": ["fr-FR/1.png"]]), library: FakeLibrary(), placements: FakePlacements()
        )

        #expect(results.map(\.status) == [.failed])
        #expect(results.map(\.message) == ["The version has no fr-FR localization"])
    }

    // MARK: - Screenshots already placed

    @Test func `should replace the screenshots already there`() async {
        let placements = FakePlacements(existing: [
            MockRepositoryFactory.makeAssetPlacement(id: "pl-old", localizationId: "loc-en", assetId: "img-old", position: 1),
        ])
        let replacing = plan(["en-US": ["en-US/1.png"]], existing: placements.all, policy: .replace)

        let results = await run(replacing, library: FakeLibrary(), placements: placements)

        #expect(results.map(\.placements) == [[ScreenshotImportPlacement(file: "en-US/1.png", imageId: "img-1", placementId: "pl-1", position: 1)]])
        #expect(placements.group("loc-en", Self.group).map(\.id) == ["pl-1"])
    }

    @Test func `should keep the screenshots already there first when appending`() async {
        let placements = FakePlacements(existing: [
            MockRepositoryFactory.makeAssetPlacement(id: "pl-old", localizationId: "loc-en", assetId: "img-old", position: 1),
        ])
        let appending = plan(["en-US": ["en-US/1.png"]], existing: placements.all, policy: .append)

        let results = await run(appending, library: FakeLibrary(), placements: placements)

        #expect(results.map(\.placements) == [[ScreenshotImportPlacement(file: "en-US/1.png", imageId: "img-1", placementId: "pl-1", position: 2)]])
        #expect(placements.group("loc-en", Self.group).map(\.id) == ["pl-old", "pl-1"])
    }

    @Test func `should leave a conflicting group as it is and upload nothing for it`() async {
        let library = FakeLibrary()
        let placements = FakePlacements(existing: [
            MockRepositoryFactory.makeAssetPlacement(id: "pl-old", localizationId: "loc-en", assetId: "img-old", position: 1),
        ])

        let results = await run(plan(["en-US": ["en-US/1.png"]], existing: placements.all), library: library, placements: placements)

        #expect(results.map(\.status) == [.conflict])
        #expect(library.images.isEmpty)
        #expect(placements.group("loc-en", Self.group).map(\.id) == ["pl-old"])
    }
}

// MARK: - In-memory App Store Connect

private struct Refused: LocalizedError {
    var errorDescription: String? { "The localization is locked" }
}

/// An asset library that keeps what it's sent. Images are processed after `readsUntilProcessed`
/// reads; files named in `failing` fail processing with that reason.
private final class FakeLibrary: LibraryImageRepository, @unchecked Sendable {
    private let lock = NSLock()
    private var stored: [LibraryImage] = []
    private var reads: [String: Int] = [:]
    private let readsUntilProcessed: Int
    private let failing: [String: AssetStateDetail]

    init(readsUntilProcessed: Int = 1, failing: [String: AssetStateDetail] = [:]) {
        self.readsUntilProcessed = readsUntilProcessed
        self.failing = failing
    }

    var images: [LibraryImage] { lock.withLock { stored } }

    func listImages(libraryId: String, imageId: String?, state: LibraryAssetState?, category: AssetCategory?) async throws -> [LibraryImage] {
        lock.withLock {
            guard let imageId, let index = stored.firstIndex(where: { $0.id == imageId }) else { return stored }
            let image = stored[index]
            reads[imageId, default: 0] += 1
            if let detail = failing[image.fileName] {
                stored[index] = MockRepositoryFactory.makeLibraryImage(id: image.id, fileName: image.fileName, state: .failed, stateDetails: [detail])
            } else if reads[imageId, default: 0] >= readsUntilProcessed {
                stored[index] = MockRepositoryFactory.makeLibraryImage(id: image.id, fileName: image.fileName, state: .prepareForSubmission)
            }
            return [stored[index]]
        }
    }

    func uploadImage(libraryId: String, fileURL: URL, category: AssetCategory, referenceName: String?) async throws -> LibraryImage {
        lock.withLock {
            let image = MockRepositoryFactory.makeLibraryImage(
                id: "img-\(stored.count + 1)", libraryId: libraryId, fileName: fileURL.lastPathComponent, state: .uploadComplete
            )
            stored.append(image)
            return image
        }
    }

    func deleteImage(imageId: String) async throws {}

    func updateImage(libraryId: String, imageId: String, referenceName: String?, isArchived: Bool?) async throws -> LibraryImage {
        guard let image = images.first(where: { $0.id == imageId }) else { throw Refused() }
        return image
    }
}

/// Placements that apply what they're sent: create appends, delete removes, reorder reorders.
private final class FakePlacements: AssetPlacementRepository, @unchecked Sendable {
    private let lock = NSLock()
    private var stored: [AssetPlacement]
    private var created = 0
    private let refusing: String?

    init(existing: [AssetPlacement] = [], refusing: String? = nil) {
        self.stored = existing
        self.refusing = refusing
    }

    var all: [AssetPlacement] { lock.withLock { stored } }

    func group(_ localizationId: String, _ group: String) -> [AssetPlacement] {
        all.filter { $0.localizationId == localizationId && $0.placementGroup == group }
    }

    func listPlacements(surface: PlacementSurface, localizationId: String, placementType: AssetPlacementType?, placementGroup: String?) async throws -> [AssetPlacement] {
        all.filter { $0.localizationId == localizationId && (placementGroup == nil || $0.placementGroup == placementGroup) }
            .enumerated().map { MockRepositoryFactory.makeAssetPlacement(id: $0.element.id, localizationId: localizationId, assetId: $0.element.assetId, placementGroup: $0.element.placementGroup, position: $0.offset + 1) }
    }

    func listAssetPlacements(mediaType: AssetMediaType, assetId: String) async throws -> [AssetPlacement] {
        all.filter { $0.assetId == assetId }
    }

    func createPlacement(surface: PlacementSurface, localizationId: String, mediaType: AssetMediaType, assetId: String, placementType: AssetPlacementType, placementGroup: String) async throws -> AssetPlacement {
        if localizationId == refusing { throw Refused() }
        return lock.withLock {
            created += 1
            let placement = MockRepositoryFactory.makeAssetPlacement(
                id: "pl-\(created)", localizationId: localizationId, assetId: assetId, placementGroup: placementGroup
            )
            stored.append(placement)
            return placement
        }
    }

    func deletePlacement(placementId: String) async throws {
        lock.withLock { stored.removeAll { $0.id == placementId } }
    }

    func reorderPlacements(surface: PlacementSurface, localizationId: String, placementGroup: String, placementIds: [String]) async throws -> [AssetPlacement] {
        lock.withLock {
            let others = stored.filter { !placementIds.contains($0.id) }
            let ordered = placementIds.compactMap { id in stored.first { $0.id == id } }
            stored = others + ordered
        }
        return try await listPlacements(surface: surface, localizationId: localizationId, placementType: nil, placementGroup: placementGroup)
    }
}
