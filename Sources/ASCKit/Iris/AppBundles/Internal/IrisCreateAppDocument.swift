import Foundation

// MARK: - Shared JSON:API building block

/// A `{"type": "...", "id": "..."}` reference used in relationships.
struct RelationshipData: Codable {
    let type: String
    let id: String
}

// MARK: - Create App Request

/// Mirrors the iris `/v1/apps` POST body.
///
/// Structure matches the real API:
/// ```json
/// { "data": { "type": "apps", "attributes": {...}, "relationships": {...} },
///   "included": [...] }
/// ```
struct AppCreateRequest: Encodable {
    let data: Data
    let included: [IncludedResource]

    struct Data: Encodable {
        let type: String
        let attributes: Attributes
        let relationships: Relationships
    }

    struct Attributes: Encodable {
        let sku: String
        let primaryLocale: String
        let bundleId: String
        let companyName: String?
    }

    struct Relationships: Encodable {
        let appStoreVersions: ToMany
        let appInfos: ToMany
    }

    struct ToMany: Encodable {
        let data: [RelationshipData]
    }
}

// MARK: - Included resources

/// A generic resource in the `included` array.
/// Covers appStoreVersions, appStoreVersionLocalizations, appInfos, appInfoLocalizations.
struct IncludedResource: Encodable {
    let type: String
    let id: String
    let attributes: [String: String]?
    let relationships: [String: IncludedRelationship]?

    struct IncludedRelationship: Encodable {
        let data: [RelationshipData]
    }
}

// MARK: - Factory

extension AppCreateRequest {

    /// Build the compound document from user-facing parameters.
    static func make(
        name: String,
        bundleId: String,
        sku: String,
        primaryLocale: String,
        platforms: [String],
        versionString: String,
        companyName: String? = nil
    ) -> AppCreateRequest {
        let appInfoId = "${new-appInfo-id}"
        let appInfoLocId = "${new-appInfoLocalization-id}"

        // One appStoreVersion per platform
        var versionRefs: [RelationshipData] = []
        var included: [IncludedResource] = []

        for platform in platforms {
            let versionId = "${store-version-\(platform.lowercased())}"
            let versionLocId = "${new-\(platform.lowercased())VersionLocalization-id}"

            versionRefs.append(RelationshipData(type: "appStoreVersions", id: versionId))

            included.append(IncludedResource(
                type: "appStoreVersions",
                id: versionId,
                attributes: ["platform": platform, "versionString": versionString],
                relationships: [
                    "appStoreVersionLocalizations": .init(data: [
                        RelationshipData(type: "appStoreVersionLocalizations", id: versionLocId),
                    ]),
                ]
            ))
            included.append(IncludedResource(
                type: "appStoreVersionLocalizations",
                id: versionLocId,
                attributes: ["locale": primaryLocale],
                relationships: nil
            ))
        }

        // appInfo + localization (carries the app name)
        included.append(IncludedResource(
            type: "appInfos",
            id: appInfoId,
            attributes: nil,
            relationships: [
                "appInfoLocalizations": .init(data: [
                    RelationshipData(type: "appInfoLocalizations", id: appInfoLocId),
                ]),
            ]
        ))
        included.append(IncludedResource(
            type: "appInfoLocalizations",
            id: appInfoLocId,
            attributes: ["locale": primaryLocale, "name": name],
            relationships: nil
        ))

        return AppCreateRequest(
            data: Data(
                type: "apps",
                attributes: Attributes(
                    sku: sku,
                    primaryLocale: primaryLocale,
                    bundleId: bundleId,
                    companyName: companyName
                ),
                relationships: Relationships(
                    appStoreVersions: ToMany(data: versionRefs),
                    appInfos: ToMany(data: [
                        RelationshipData(type: "appInfos", id: appInfoId),
                    ])
                )
            ),
            included: included
        )
    }
}
