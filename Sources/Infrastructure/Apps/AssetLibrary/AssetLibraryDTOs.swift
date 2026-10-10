@preconcurrency import AppStoreConnect_Swift_SDK
import Foundation

// asc decodes App Asset Library responses into its own documents instead of the SDK's
// generated types:
// - images/videos: the SDK switches on `state` to pick an attributes type, so a state
//   Apple adds later fails the whole list; here state, category and the rest stay strings
//   and the mapper skips what the domain can't name.
// - placements: the SDK expects `mediaType` inside `relationships`, but Apple sends it in
//   `attributes`, so every placement fails to decode.
// - reference data: identifiers are strings by Apple's design; the SDK's enums for
//   platforms and display classes would throw on a new device.

/// `meta.paging.nextCursor`, for `requestAllPages`.
struct PagingMeta: Decodable {
    struct Paging: Decodable {
        let nextCursor: String?
    }
    let paging: Paging?
}

/// A `{"data": {"type", "id"}}` relationship linkage.
struct LinkageDTO: Decodable {
    struct Identifier: Decodable {
        let id: String
    }
    let data: Identifier?
}

struct StateDetailDTO: Decodable {
    let code: String?
    let description: String?
}

// MARK: - Images and videos

struct LibraryAssetResource: Decodable {
    struct Attributes: Decodable {
        struct ImageAssetDTO: Decodable {
            let templateUrl: String?
            let width: Int?
            let height: Int?
        }

        let category: String?
        let createdDate: String?
        let fileName: String?
        let fileSize: Int?
        let referenceName: String?
        let specId: String?
        let state: String?
        let stateDetails: [StateDetailDTO]?
        let imageAsset: ImageAssetDTO?
        let uploadOperations: [UploadOperation]?
    }

    let id: String
    let attributes: Attributes?
}

struct LibraryAssetDocument: Decodable {
    let data: LibraryAssetResource
}

struct LibraryAssetsDocument: Decodable {
    let data: [LibraryAssetResource]
    let meta: PagingMeta?
}

// MARK: - Reference data

struct AssetRefDataDocument: Decodable {
    struct Datum: Decodable {
        let attributes: Attributes?
    }

    struct Attributes: Decodable {
        struct Feature: Decodable {
            struct Policy: Decodable {
                struct GroupLimit: Decodable {
                    let groupIds: [String]?
                    let maxCount: Int?
                }
                let placementType: String?
                let groupLimits: [GroupLimit]?
            }
            let featureId: String?
            let placementPolicies: [Policy]?
        }

        struct ProfileGroup: Decodable {
            let placementProfileGroupId: String?
            let platform: String?
            let displayClassId: String?
        }

        struct Spec: Decodable {
            struct Dimensions: Decodable {
                let minWidth: Int?
                let minHeight: Int?
            }
            let specId: String?
            let dimensions: Dimensions?
        }

        struct PlacementType: Decodable {
            struct SpecMapping: Decodable {
                let placementGroupId: String?
                let specs: [String]?
            }
            let placementTypeId: String?
            let specMappings: [SpecMapping]?
        }

        let features: [Feature]?
        let placementProfileGroups: [ProfileGroup]?
        let imageSpecs: [Spec]?
        let videoSpecs: [Spec]?
        let placementTypes: [PlacementType]?
    }

    let data: [Datum]
}
