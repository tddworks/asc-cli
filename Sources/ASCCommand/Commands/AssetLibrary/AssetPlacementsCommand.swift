import ArgumentParser
import Domain

struct AssetPlacementsCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "asset-placements",
        abstract: "Place asset library images and videos on localizations, and order them",
        subcommands: [AssetPlacementsList.self, AssetPlacementsCreate.self, AssetPlacementsDelete.self, AssetPlacementsReorder.self]
    )
}

struct AssetPlacementsList: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "list",
        abstract: "List the placements on a localization, or everywhere an image or video is placed"
    )

    @OptionGroup var globals: GlobalOptions
    @OptionGroup var surface: PlacementSurfaceOptions

    @Option(name: .long, help: "Asset library image ID")
    var imageId: String?

    @Option(name: .long, help: "Asset library video ID")
    var videoId: String?

    @Option(name: .long, help: "Only this placement type (with a localization)")
    var placementType: AssetPlacementType?

    @Option(name: .long, help: "Only this placement group (with a localization)")
    var placementGroup: String?

    func validate() throws {
        let parents = [surface.localizationId, surface.treatmentLocalizationId, imageId, videoId].compactMap { $0 }
        guard parents.count == 1 else {
            throw ValidationError("Pass exactly one of --localization-id, --treatment-localization-id, --image-id or --video-id")
        }
        if surface.selected == nil, placementType != nil || placementGroup != nil {
            throw ValidationError("--placement-type and --placement-group filter a localization's placements; use them with --localization-id or --treatment-localization-id")
        }
    }

    func run() async throws {
        let repo = try ClientProvider.makeAssetPlacementRepository()
        print(try await execute(repo: repo))
    }

    func execute(repo: any AssetPlacementRepository, affordanceMode: AffordanceMode = .cli) async throws -> String {
        let placements: [AssetPlacement]
        if let (surface, localizationId) = surface.selected {
            placements = try await repo.listPlacements(
                surface: surface, localizationId: localizationId,
                placementType: placementType, placementGroup: placementGroup
            )
        } else if let videoId {
            placements = try await repo.listAssetPlacements(mediaType: .video, assetId: videoId)
        } else {
            placements = try await repo.listAssetPlacements(mediaType: .image, assetId: imageId ?? "")
        }
        let formatter = OutputFormatter(format: globals.outputFormat, pretty: globals.pretty)
        return try formatter.formatAgentItems(placements, affordanceMode: affordanceMode)
    }
}

struct AssetPlacementsCreate: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "create",
        abstract: "Place a library image or video in one slot of a localization (its version must be editable)"
    )

    @OptionGroup var globals: GlobalOptions
    @OptionGroup var surface: PlacementSurfaceOptions

    @Option(name: .long, help: "Asset library image ID")
    var imageId: String?

    @Option(name: .long, help: "Asset library video ID")
    var videoId: String?

    @Option(name: .long, help: "Placement type, e.g. APP_SCREENSHOT")
    var placementType: AssetPlacementType

    @Option(name: .long, help: "Placement group from `asc asset-placement-groups list`, e.g. IPHONE_DYNAMIC_ISLAND_LARGE_PROFILE")
    var placementGroup: String

    func validate() throws {
        try surface.validateExactlyOne()
        guard (imageId == nil) != (videoId == nil) else {
            throw ValidationError("Pass exactly one of --image-id or --video-id")
        }
    }

    func run() async throws {
        let repo = try ClientProvider.makeAssetPlacementRepository()
        print(try await execute(repo: repo))
    }

    func execute(repo: any AssetPlacementRepository, affordanceMode: AffordanceMode = .cli) async throws -> String {
        guard let (surface, localizationId) = surface.selected else { throw ValidationError("Pass a localization") }
        let (mediaType, assetId): (AssetMediaType, String) = videoId.map { (.video, $0) } ?? (.image, imageId ?? "")
        let placement = try await repo.createPlacement(
            surface: surface, localizationId: localizationId, mediaType: mediaType, assetId: assetId,
            placementType: placementType, placementGroup: placementGroup
        )
        let formatter = OutputFormatter(format: globals.outputFormat, pretty: globals.pretty)
        return try formatter.formatAgentItems([placement], affordanceMode: affordanceMode)
    }
}

struct AssetPlacementsDelete: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "delete",
        abstract: "Remove a placement (the asset stays in the library)"
    )

    @OptionGroup var globals: GlobalOptions

    @Option(name: .long, help: "Placement ID")
    var placementId: String

    func run() async throws {
        let repo = try ClientProvider.makeAssetPlacementRepository()
        try await execute(repo: repo)
    }

    func execute(repo: any AssetPlacementRepository) async throws {
        try await repo.deletePlacement(placementId: placementId)
    }
}

struct AssetPlacementsReorder: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "reorder",
        abstract: "Set the display order of one placement group on a localization"
    )

    @OptionGroup var globals: GlobalOptions
    @OptionGroup var surface: PlacementSurfaceOptions

    @Option(name: .long, help: "Placement group to order")
    var placementGroup: String

    @Option(name: .long, help: "Placement IDs in display order, comma-separated")
    var placementIds: String

    func validate() throws {
        try surface.validateExactlyOne()
    }

    func run() async throws {
        let repo = try ClientProvider.makeAssetPlacementRepository()
        print(try await execute(repo: repo))
    }

    func execute(repo: any AssetPlacementRepository, affordanceMode: AffordanceMode = .cli) async throws -> String {
        let ids = placementIds.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
        guard let (surface, localizationId) = surface.selected else { throw ValidationError("Pass a localization") }
        let placements = try await repo.reorderPlacements(
            surface: surface, localizationId: localizationId, placementGroup: placementGroup, placementIds: ids
        )
        let formatter = OutputFormatter(format: globals.outputFormat, pretty: globals.pretty)
        return try formatter.formatAgentItems(placements, affordanceMode: affordanceMode)
    }
}

/// The localization a placement sits on: an App Store version localization or a product
/// page optimization treatment localization.
struct PlacementSurfaceOptions: ParsableArguments {
    @Option(name: .long, help: "App Store version localization ID")
    var localizationId: String?

    @Option(name: .long, help: "Product page optimization treatment localization ID")
    var treatmentLocalizationId: String?

    var selected: (PlacementSurface, String)? {
        if let localizationId { return (.appStoreVersionLocalization, localizationId) }
        if let treatmentLocalizationId { return (.experimentTreatmentLocalization, treatmentLocalizationId) }
        return nil
    }

    func validateExactlyOne() throws {
        guard (localizationId == nil) != (treatmentLocalizationId == nil) else {
            throw ValidationError("Pass exactly one of --localization-id or --treatment-localization-id")
        }
    }
}
