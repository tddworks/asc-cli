import Foundation

/// What to do with screenshots a localization already has in a placement group.
public enum ExistingScreenshotsPolicy: String, Sendable, Equatable, Codable, CaseIterable {
    /// Leave the group alone and report a conflict.
    case fail
    /// Delete the editable screenshots, then place the imported ones.
    case replace
    /// Keep the screenshots there and place the imported ones after them.
    case append
}

/// One screenshot from an export ZIP, measured and hashed by the caller — Domain does no I/O.
public struct ScreenshotImportFile: Sendable, Equatable {
    /// The path inside the ZIP, as the manifest names it.
    public let file: String
    /// Where the extracted file is.
    public let url: URL
    /// SHA-256 of the file's bytes; identical files are uploaded once.
    public let contentHash: String
    public let width: Int
    public let height: Int

    public init(file: String, url: URL, contentHash: String, width: Int, height: Int) {
        self.file = file
        self.url = url
        self.contentHash = contentHash
        self.width = width
        self.height = height
    }

    /// The pixel size the way placement groups list it, `"WxH"`.
    public var size: String { "\(width)x\(height)" }
}

/// One locale's screenshots for one placement group, as planned.
public struct PlannedGroup: Sendable, Equatable {
    public let locale: String
    public let localizationId: String?
    public let versionId: String?
    public let placementGroup: String?
    public let status: ScreenshotImportStatus
    /// In manifest order.
    public let files: [ScreenshotImportFile]
    /// What the localization already has in the group, in display order.
    public let existing: [AssetPlacement]
    public let message: String?
    public let candidates: [String]?

    /// The group as a dry run reports it.
    public var result: ScreenshotImportGroupResult {
        ScreenshotImportGroupResult(
            locale: locale, localizationId: localizationId, versionId: versionId, placementGroup: placementGroup,
            status: status, placements: files.map { ScreenshotImportPlacement(file: $0.file) }, message: message,
            existingPlacementIds: status == .conflict ? existing.map(\.id) : nil, candidates: candidates
        )
    }
}

/// How an export ZIP's screenshots go into the app's asset library and onto a version's
/// localizations: which placement group each screenshot fills and what has to be uploaded.
public struct ScreenshotImportPlan: Sendable, Equatable {
    public let groups: [PlannedGroup]
    /// One file per distinct content hash among the groups that will be placed.
    public let uniqueUploads: [ScreenshotImportFile]
    public let policy: ExistingScreenshotsPolicy

    /// The feature whose screenshot slots a version localization has.
    static let versionFeature = "APP_STORE_VERSIONS"

    /// Every group as a dry run reports it.
    public var results: [ScreenshotImportGroupResult] { groups.map(\.result) }

    /// Matches each screenshot's exact size to the version screenshot placement groups,
    /// using `overrides` when a size fits several, then checks limits and existing screenshots.
    public static func plan(
        manifest: ScreenshotManifest,
        files: [ScreenshotImportFile],
        groups: [AssetPlacementGroup],
        localizations: [AppStoreVersionLocalization],
        existing: [AssetPlacement],
        overrides: [String],
        policy: ExistingScreenshotsPolicy
    ) -> ScreenshotImportPlan {
        var slots: [AssetPlacementGroup] = []
        for group in groups
        where group.placementType == .appScreenshot && group.feature == versionFeature && !slots.contains(where: { $0.id == group.id }) {
            slots.append(group)
        }
        let filesByPath = Dictionary(files.map { ($0.file, $0) }, uniquingKeysWith: { first, _ in first })

        var planned: [PlannedGroup] = []
        for (locale, localeManifest) in manifest.localizations.sorted(by: { $0.key < $1.key }) {
            let localization = localizations.first { $0.locale == locale }
            var buckets: [(group: String?, candidates: [String], size: String, files: [ScreenshotImportFile])] = []
            for entry in localeManifest.screenshots.sorted(by: { $0.order < $1.order }) {
                guard let file = filesByPath[entry.file] else { continue }
                let candidates = slots.filter { $0.sizes.contains(file.size) }.map(\.id)
                let group: String? = candidates.count == 1 ? candidates[0] : overrides.first { candidates.contains($0) }
                if let index = buckets.firstIndex(where: { group != nil ? $0.group == group : ($0.group == nil && $0.size == file.size) }) {
                    buckets[index].files.append(file)
                } else {
                    buckets.append((group, candidates, file.size, [file]))
                }
            }
            for bucket in buckets {
                let inGroup = existing
                    .filter { $0.localizationId == localization?.id && $0.placementGroup == bucket.group }
                    .sorted { ($0.position ?? .max) < ($1.position ?? .max) }
                let (status, message) = assess(
                    bucket: bucket, slot: slots.first { $0.id == bucket.group }, existing: inGroup, policy: policy
                )
                planned.append(PlannedGroup(
                    locale: locale, localizationId: localization?.id, versionId: localization?.versionId,
                    placementGroup: bucket.group, status: status, files: bucket.files, existing: inGroup, message: message,
                    candidates: status == .ambiguous ? bucket.candidates : nil
                ))
            }
        }

        var uploads: [ScreenshotImportFile] = []
        for file in planned.filter({ $0.status == .planned }).flatMap(\.files) where !uploads.contains(where: { $0.contentHash == file.contentHash }) {
            uploads.append(file)
        }
        return ScreenshotImportPlan(groups: planned, uniqueUploads: uploads, policy: policy)
    }

    private static func assess(
        bucket: (group: String?, candidates: [String], size: String, files: [ScreenshotImportFile]),
        slot: AssetPlacementGroup?,
        existing: [AssetPlacement],
        policy: ExistingScreenshotsPolicy
    ) -> (ScreenshotImportStatus, String?) {
        guard let slot else {
            if bucket.candidates.count > 1 {
                return (.ambiguous, "\(bucket.size) fits several placement groups — pass --placement-group with one of them")
            }
            return (.noMatchingGroup, "No \(AssetPlacementType.appScreenshot.rawValue) placement group accepts \(bucket.size)")
        }
        if policy == .fail, !existing.isEmpty {
            return (.conflict, "The localization already has \(existing.count) screenshots in this group — pass --existing replace or --existing append")
        }
        let count = bucket.files.count + kept(existing, policy: policy).count
        if let maxCount = slot.maxCount, count > maxCount {
            return (.overLimit, "\(count) screenshots exceed the group's limit of \(maxCount)")
        }
        return (.planned, nil)
    }

    /// The screenshots that stay in the group: all of them when appending; when replacing,
    /// those App Store Connect no longer lets you delete.
    static func kept(_ existing: [AssetPlacement], policy: ExistingScreenshotsPolicy) -> [AssetPlacement] {
        policy == .replace ? existing.filter { !$0.state.isEditable } : existing
    }
}

// MARK: - Executing

extension ScreenshotImportPlan {
    /// Uploads each distinct screenshot once, waits until App Store Connect has processed
    /// them, then places and orders each planned group. A group that can't be placed is
    /// reported as `failed`; the others carry on.
    public func execute(
        libraryId: String,
        imageRepo: any LibraryImageRepository,
        placementRepo: any AssetPlacementRepository,
        sleep: @Sendable (UInt64) async throws -> Void
    ) async -> [ScreenshotImportGroupResult] {
        var imageIds: [String: String] = [:]
        var failures: [String: String] = [:]

        var uploaded: [(file: ScreenshotImportFile, image: LibraryImage)] = []
        for file in uniqueUploads {
            do {
                let image = try await imageRepo.uploadImage(
                    libraryId: libraryId, fileURL: file.url, category: .appScreenshotsAndPreviews, referenceName: nil
                )
                uploaded.append((file, image))
            } catch {
                failures[file.contentHash] = "Couldn't upload \(file.file): \(Self.describe(error))"
            }
        }

        for (file, image) in uploaded {
            do {
                let processed = try await AssetProcessingWait.untilProcessed(
                    image, isPending: { $0.state.isAwaitingUpload || $0.state.isProcessing }, sleep: sleep
                ) {
                    try await imageRepo.listImages(libraryId: libraryId, imageId: image.id, state: nil, category: nil).first
                }
                if processed.state.isFailed {
                    let reasons = (processed.stateDetails ?? [])
                        .map { [$0.code, $0.description].compactMap { $0 }.joined(separator: " ") }
                        .joined(separator: "; ")
                    failures[file.contentHash] = "App Store Connect couldn't process \(file.file): \(reasons)"
                } else if processed.state.isAwaitingUpload || processed.state.isProcessing {
                    failures[file.contentHash] = "App Store Connect is still processing \(file.file) — check `asc asset-images list` and place it later"
                } else {
                    imageIds[file.contentHash] = processed.id
                }
            } catch {
                failures[file.contentHash] = Self.describe(error)
            }
        }

        var results: [ScreenshotImportGroupResult] = []
        for group in groups {
            guard group.status == .planned else {
                results.append(group.result)
                continue
            }
            results.append(await place(group, imageIds: imageIds, failures: failures, placementRepo: placementRepo))
        }
        return results
    }

    private func place(
        _ group: PlannedGroup,
        imageIds: [String: String],
        failures: [String: String],
        placementRepo: any AssetPlacementRepository
    ) async -> ScreenshotImportGroupResult {
        func failed(_ message: String) -> ScreenshotImportGroupResult {
            ScreenshotImportGroupResult(
                locale: group.locale, localizationId: group.localizationId, versionId: group.versionId,
                placementGroup: group.placementGroup, status: .failed,
                placements: group.files.map { ScreenshotImportPlacement(file: $0.file) }, message: message
            )
        }
        guard let localizationId = group.localizationId, let placementGroup = group.placementGroup else {
            return failed("The version has no \(group.locale) localization")
        }
        if let failure = group.files.lazy.compactMap({ failures[$0.contentHash] }).first {
            return failed(failure)
        }
        do {
            if policy == .replace {
                for placement in group.existing where placement.state.isEditable {
                    try await placementRepo.deletePlacement(placementId: placement.id)
                }
            }
            var created: [AssetPlacement] = []
            for file in group.files {
                guard let imageId = imageIds[file.contentHash] else { return failed("\(file.file) wasn't uploaded") }
                created.append(try await placementRepo.createPlacement(
                    surface: .appStoreVersionLocalization, localizationId: localizationId, mediaType: .image,
                    assetId: imageId, placementType: .appScreenshot, placementGroup: placementGroup
                ))
            }
            let order = Self.kept(group.existing, policy: policy).map(\.id) + created.map(\.id)
            let ordered = try await placementRepo.reorderPlacements(
                surface: .appStoreVersionLocalization, localizationId: localizationId,
                placementGroup: placementGroup, placementIds: order
            )
            let positions = Dictionary(ordered.map { ($0.id, $0.position) }, uniquingKeysWith: { first, _ in first })
            return ScreenshotImportGroupResult(
                locale: group.locale, localizationId: localizationId, versionId: group.versionId,
                placementGroup: placementGroup, status: .placed,
                placements: zip(group.files, created).map { file, placement in
                    ScreenshotImportPlacement(
                        file: file.file, imageId: placement.assetId, placementId: placement.id,
                        position: positions[placement.id] ?? nil
                    )
                }
            )
        } catch {
            return failed(Self.describe(error))
        }
    }

    static func describe(_ error: any Error) -> String {
        (error as? LocalizedError)?.errorDescription ?? String(describing: error)
    }
}
