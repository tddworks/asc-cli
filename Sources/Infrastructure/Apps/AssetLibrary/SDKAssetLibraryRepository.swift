@preconcurrency import AppStoreConnect_Swift_SDK
import Domain
import Foundation

public struct SDKAssetLibraryRepository: AssetLibraryRepository, @unchecked Sendable {
    private let client: any APIClient

    public init(client: any APIClient) {
        self.client = client
    }

    public func getAssetLibrary(appId: String) async throws -> Domain.AppAssetLibrary {
        let response = try await client.request(APIEndpoint.v1.apps.id(appId).assetLibrary.get())
        return Domain.AppAssetLibrary(id: response.data.id, appId: appId)
    }

    public func listPlacementGroups(placementType: AssetPlacementType?, feature: String?) async throws -> [AssetPlacementGroup] {
        let sdk = APIEndpoint.v1.appAssetLibraryRefData.get(parameters: .init(
            filterPlacementTypes: placementType.map { [$0.rawValue] },
            filterFeatures: feature.map { [$0] }
        ))
        let document = try await client.request(
            Request<AssetRefDataDocument>(path: sdk.path, method: "GET", query: sdk.query, id: "appAssetLibraryRefData_getCollection")
        )
        return document.data.compactMap(\.attributes).flatMap {
            flatten($0, placementType: placementType, feature: feature)
        }
    }

    /// One row per placement type × group × feature limiting it. A group no feature caps
    /// still gets one row (feature and limit unknown) unless a feature was asked for.
    private func flatten(
        _ catalog: AssetRefDataDocument.Attributes,
        placementType requestedType: AssetPlacementType?,
        feature requestedFeature: String?
    ) -> [AssetPlacementGroup] {
        let profiles = Dictionary(
            (catalog.placementProfileGroups ?? []).compactMap { p in p.placementProfileGroupId.map { ($0, p) } },
            uniquingKeysWith: { first, _ in first }
        )
        let sizes = Dictionary(
            ((catalog.imageSpecs ?? []) + (catalog.videoSpecs ?? [])).compactMap { spec -> (String, String)? in
                guard let id = spec.specId, let w = spec.dimensions?.minWidth, let h = spec.dimensions?.minHeight else { return nil }
                return (id, "\(w)x\(h)")
            },
            uniquingKeysWith: { first, _ in first }
        )
        let features = (catalog.features ?? []).filter { requestedFeature == nil || $0.featureId == requestedFeature }

        var rows: [AssetPlacementGroup] = []
        for type in catalog.placementTypes ?? [] {
            guard let typeId = type.placementTypeId, let placementType = AssetPlacementType(rawValue: typeId),
                  requestedType == nil || placementType == requestedType
            else { continue }

            for mapping in type.specMappings ?? [] {
                guard let group = mapping.placementGroupId else { continue }
                let profile = profiles[group]
                var groupSizes: [String] = []
                for size in (mapping.specs ?? []).compactMap({ sizes[$0] }) where !groupSizes.contains(size) {
                    groupSizes.append(size)
                }
                let limits: [(feature: String?, maxCount: Int?)] = features.compactMap { feature in
                    let limit = feature.placementPolicies?
                        .first { $0.placementType == typeId }?
                        .groupLimits?.first { $0.groupIds?.contains(group) == true }
                    return limit.map { (feature.featureId, $0.maxCount) }
                }
                let rowLimits = limits.isEmpty && requestedFeature == nil ? [(feature: nil, maxCount: nil)] : limits
                for limit in rowLimits {
                    rows.append(AssetPlacementGroup(
                        id: group, placementType: placementType,
                        platform: profile?.platform, displayClass: profile?.displayClassId,
                        feature: limit.feature, sizes: groupSizes, maxCount: limit.maxCount
                    ))
                }
            }
        }
        return rows
    }
}
