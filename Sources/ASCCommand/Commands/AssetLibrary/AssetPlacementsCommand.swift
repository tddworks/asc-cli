import ArgumentParser
import Domain

struct AssetPlacementsCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "asset-placements",
        abstract: "Place asset library images on localizations, and order them",
        subcommands: [AssetPlacementsList.self, AssetPlacementsCreate.self, AssetPlacementsDelete.self, AssetPlacementsReorder.self]
    )
}

struct AssetPlacementsList: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "list",
        abstract: "List the placements on a version localization, or everywhere an image is placed"
    )

    @OptionGroup var globals: GlobalOptions

    @Option(name: .long, help: "App Store version localization ID")
    var localizationId: String?

    @Option(name: .long, help: "Asset library image ID")
    var imageId: String?

    @Option(name: .long, help: "Only this placement type (with --localization-id)")
    var placementType: AssetPlacementType?

    @Option(name: .long, help: "Only this placement group (with --localization-id)")
    var placementGroup: String?

    func validate() throws {
        guard (localizationId == nil) != (imageId == nil) else {
            throw ValidationError("Pass exactly one of --localization-id or --image-id")
        }
        if imageId != nil, placementType != nil || placementGroup != nil {
            throw ValidationError("--placement-type and --placement-group filter a localization's placements; use them with --localization-id")
        }
    }

    func run() async throws {
        let repo = try ClientProvider.makeAssetPlacementRepository()
        print(try await execute(repo: repo))
    }

    func execute(repo: any AssetPlacementRepository, affordanceMode: AffordanceMode = .cli) async throws -> String {
        let placements: [AssetPlacement]
        if let localizationId {
            placements = try await repo.listPlacements(
                surface: .appStoreVersionLocalization, localizationId: localizationId,
                placementType: placementType, placementGroup: placementGroup
            )
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
        abstract: "Place a library image in one slot of a version localization (the version must be editable)"
    )

    @OptionGroup var globals: GlobalOptions

    @Option(name: .long, help: "App Store version localization ID")
    var localizationId: String

    @Option(name: .long, help: "Asset library image ID")
    var imageId: String

    @Option(name: .long, help: "Placement type, e.g. APP_SCREENSHOT")
    var placementType: AssetPlacementType

    @Option(name: .long, help: "Placement group from `asc asset-placement-groups list`, e.g. IPHONE_DYNAMIC_ISLAND_LARGE_PROFILE")
    var placementGroup: String

    func run() async throws {
        let repo = try ClientProvider.makeAssetPlacementRepository()
        print(try await execute(repo: repo))
    }

    func execute(repo: any AssetPlacementRepository, affordanceMode: AffordanceMode = .cli) async throws -> String {
        let placement = try await repo.createPlacement(
            surface: .appStoreVersionLocalization, localizationId: localizationId, mediaType: .image, assetId: imageId,
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
        abstract: "Set the display order of one placement group on a version localization"
    )

    @OptionGroup var globals: GlobalOptions

    @Option(name: .long, help: "App Store version localization ID")
    var localizationId: String

    @Option(name: .long, help: "Placement group to order")
    var placementGroup: String

    @Option(name: .long, help: "Placement IDs in display order, comma-separated")
    var placementIds: String

    func run() async throws {
        let repo = try ClientProvider.makeAssetPlacementRepository()
        print(try await execute(repo: repo))
    }

    func execute(repo: any AssetPlacementRepository, affordanceMode: AffordanceMode = .cli) async throws -> String {
        let ids = placementIds.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
        let placements = try await repo.reorderPlacements(
            surface: .appStoreVersionLocalization, localizationId: localizationId, placementGroup: placementGroup, placementIds: ids
        )
        let formatter = OutputFormatter(format: globals.outputFormat, pretty: globals.pretty)
        return try formatter.formatAgentItems(placements, affordanceMode: affordanceMode)
    }
}
