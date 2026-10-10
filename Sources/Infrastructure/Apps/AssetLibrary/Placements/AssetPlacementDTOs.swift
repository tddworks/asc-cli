import Domain
import Foundation

// MARK: - Responses (see AssetLibraryDTOs.swift for why asc decodes its own types)

struct AssetPlacementResource: Decodable {
    struct Attributes: Decodable {
        let mediaType: String?
        let placementType: String?
        let placementGroup: String?
        let state: String?
        let stateDetails: [StateDetailDTO]?
    }

    struct Relationships: Decodable {
        let image: LinkageDTO?
        let video: LinkageDTO?
        let appStoreVersionLocalization: LinkageDTO?
        let appStoreVersionExperimentTreatmentLocalization: LinkageDTO?
        let appCustomProductPageLocalization: LinkageDTO?
        let appEventLocalization: LinkageDTO?
    }

    let id: String
    let attributes: Attributes?
    let relationships: Relationships?
}

struct AssetPlacementDocument: Decodable {
    let data: AssetPlacementResource
}

struct AssetPlacementsDocument: Decodable {
    let data: [AssetPlacementResource]
    let meta: PagingMeta?
}

struct PlacementOrderingDocument: Decodable {
    struct Resource: Decodable {
        let id: String
    }
    let data: Resource
}

// MARK: - Request bodies
//
// The SDK's `AppAssetLibraryPlacementCreateRequest` and `…OrderingRequestCreateRequest`
// are generated without a `type` and with untyped fields, so asc builds the bodies itself.

struct ResourceIdentifierBody: Encodable {
    let type: String
    let id: String
}

struct ToOneBody: Encodable {
    let data: ResourceIdentifierBody
}

struct ToManyBody: Encodable {
    let data: [ResourceIdentifierBody]
}

struct PlacementCreateBody: Encodable {
    struct Data: Encodable {
        struct Attributes: Encodable {
            let placementType: String
            let placementGroup: String
        }
        let type = "appAssetLibraryPlacements"
        let attributes: Attributes
        let relationships: [String: ToOneBody]
    }
    let data: Data
}

struct PlacementOrderingBody: Encodable {
    struct Data: Encodable {
        struct Attributes: Encodable {
            let placementGroup: String
        }
        struct Relationships: Encodable {
            let surfaceKey: String
            let surface: ToOneBody
            let orderedPlacements: ToManyBody

            private struct Key: CodingKey {
                let stringValue: String
                var intValue: Int? { nil }
                init(_ string: String) { stringValue = string }
                init?(stringValue: String) { self.stringValue = stringValue }
                init?(intValue: Int) { nil }
            }

            func encode(to encoder: any Encoder) throws {
                var c = encoder.container(keyedBy: Key.self)
                try c.encode(surface, forKey: Key(surfaceKey))
                try c.encode(orderedPlacements, forKey: Key("orderedPlacements"))
            }
        }
        let type = "appAssetLibraryPlacementOrderingRequests"
        let attributes: Attributes
        let relationships: Relationships
    }
    let data: Data
}

// MARK: - Surfaces on the wire

extension PlacementSurface {
    /// The placement relationship naming a localization of this surface.
    var relationshipKey: String {
        switch self {
        case .appStoreVersionLocalization: "appStoreVersionLocalization"
        case .experimentTreatmentLocalization: "appStoreVersionExperimentTreatmentLocalization"
        case .customProductPageLocalization: "appCustomProductPageLocalization"
        case .eventLocalization: "appEventLocalization"
        }
    }

    /// The JSON:API resource type of a localization of this surface.
    var resourceType: String { relationshipKey + "s" }
}

extension AssetMediaType {
    var relationshipKey: String {
        switch self {
        case .image: "image"
        case .video: "video"
        }
    }

    var resourceType: String {
        switch self {
        case .image: "appAssetLibraryImages"
        case .video: "appAssetLibraryVideos"
        }
    }
}
