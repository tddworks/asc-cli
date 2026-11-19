@preconcurrency import AppStoreConnect_Swift_SDK
import Foundation

/// Adapts the App Store Connect "product page optimization" endpoints
/// (`appStoreVersionExperiments` v2 + treatments + treatment localizations).
public struct SDKExperiments: Experiments, @unchecked Sendable {
    private let client: any APIClient

    public init(client: any APIClient) {
        self.client = client
    }

    // MARK: - Experiments

    public func listExperiments(
        appId: String,
        state: ASCKit.AppStoreVersionExperimentState?,
        limit: Int?
    ) async throws -> PaginatedResponse<ASCKit.AppStoreVersionExperiment> {
        let filterState = state.flatMap {
            APIEndpoint.V1.Apps.WithID.AppStoreVersionExperimentsV2.GetParameters.FilterState(rawValue: $0.rawValue)
        }
        let request = APIEndpoint.v1.apps.id(appId).appStoreVersionExperimentsV2.get(
            parameters: .init(filterState: filterState.map { [$0] }, limit: limit)
        )
        let response = try await client.request(request)
        let experiments = response.data.map { mapExperiment($0, appId: appId) }
        return PaginatedResponse(data: experiments, nextCursor: response.links.next)
    }

    public func getExperiment(experimentId: String) async throws -> ASCKit.AppStoreVersionExperiment {
        // Apple omits `relationships.app` unless it is explicitly included; without it
        // the model's appId (and every `--app-id` affordance) would be empty.
        let request = APIEndpoint.v2.appStoreVersionExperiments.id(experimentId).get(parameters: .init(include: [.app]))
        let response = try await client.request(request)
        return mapExperiment(response.data, appId: response.data.relationships?.app?.data?.id ?? "")
    }

    public func createExperiment(
        appId: String,
        name: String,
        platform: ASCKit.AppStorePlatform,
        trafficProportion: Int
    ) async throws -> ASCKit.AppStoreVersionExperiment {
        guard let sdkPlatform = AppStoreConnect_Swift_SDK.Platform(rawValue: platform.rawValue) else {
            throw ASCKit.APIError.unknown("Unsupported platform for create: \(platform.rawValue)")
        }
        let body = AppStoreVersionExperimentV2CreateRequest(data: .init(
            type: .appStoreVersionExperiments,
            attributes: .init(name: name, platform: sdkPlatform, trafficProportion: trafficProportion),
            relationships: .init(app: .init(data: .init(type: .apps, id: appId)))
        ))
        let response = try await client.request(APIEndpoint.v2.appStoreVersionExperiments.post(body))
        return mapExperiment(response.data, appId: appId)
    }

    public func updateExperiment(
        experimentId: String,
        name: String?,
        trafficProportion: Int?,
        isStarted: Bool?
    ) async throws -> ASCKit.AppStoreVersionExperiment {
        let body = AppStoreVersionExperimentV2UpdateRequest(data: .init(
            type: .appStoreVersionExperiments,
            id: experimentId,
            attributes: .init(name: name, trafficProportion: trafficProportion, isStarted: isStarted)
        ))
        _ = try await client.request(APIEndpoint.v2.appStoreVersionExperiments.id(experimentId).patch(body))
        // PATCH responses carry no relationships, so re-read with `include=app` to keep appId populated.
        return try await getExperiment(experimentId: experimentId)
    }

    public func deleteExperiment(experimentId: String) async throws {
        _ = try await client.request(APIEndpoint.v2.appStoreVersionExperiments.id(experimentId).delete)
    }

    // MARK: - Treatments

    public func listTreatments(experimentId: String, limit: Int?) async throws -> PaginatedResponse<ASCKit.ExperimentTreatment> {
        let request = APIEndpoint.v2.appStoreVersionExperiments.id(experimentId)
            .appStoreVersionExperimentTreatments.get(parameters: .init(limit: limit))
        let response = try await client.request(request)
        let treatments = response.data.map { mapTreatment($0, experimentId: experimentId) }
        return PaginatedResponse(data: treatments, nextCursor: response.links.next)
    }

    public func createTreatment(experimentId: String, name: String, appIconName: String?) async throws -> ASCKit.ExperimentTreatment {
        let body = AppStoreVersionExperimentTreatmentCreateRequest(data: .init(
            type: .appStoreVersionExperimentTreatments,
            attributes: .init(name: name, appIconName: appIconName),
            relationships: .init(
                appStoreVersionExperimentV2: .init(data: .init(type: .appStoreVersionExperiments, id: experimentId))
            )
        ))
        let response = try await client.request(APIEndpoint.v1.appStoreVersionExperimentTreatments.post(body))
        return mapTreatment(response.data, experimentId: experimentId)
    }

    public func updateTreatment(treatmentId: String, name: String?, appIconName: String?) async throws -> ASCKit.ExperimentTreatment {
        let body = AppStoreVersionExperimentTreatmentUpdateRequest(data: .init(
            type: .appStoreVersionExperimentTreatments,
            id: treatmentId,
            attributes: .init(name: name, appIconName: appIconName)
        ))
        _ = try await client.request(APIEndpoint.v1.appStoreVersionExperimentTreatments.id(treatmentId).patch(body))
        // Same as experiments: the PATCH response has no relationships, so re-read
        // with the parent included to keep experimentId populated.
        let request = APIEndpoint.v1.appStoreVersionExperimentTreatments.id(treatmentId)
            .get(parameters: .init(include: [.appStoreVersionExperimentV2]))
        let response = try await client.request(request)
        let parentId = response.data.relationships?.appStoreVersionExperimentV2?.data?.id
            ?? response.data.relationships?.appStoreVersionExperiment?.data?.id
            ?? ""
        return mapTreatment(response.data, experimentId: parentId)
    }

    public func deleteTreatment(treatmentId: String) async throws {
        _ = try await client.request(APIEndpoint.v1.appStoreVersionExperimentTreatments.id(treatmentId).delete)
    }

    // MARK: - Treatment localizations

    public func listTreatmentLocalizations(treatmentId: String, limit: Int?) async throws -> [ASCKit.ExperimentTreatmentLocalization] {
        let request = APIEndpoint.v1.appStoreVersionExperimentTreatments.id(treatmentId)
            .appStoreVersionExperimentTreatmentLocalizations.get(parameters: .init(limit: limit))
        let response = try await client.request(request)
        return response.data.map { mapLocalization($0, treatmentId: treatmentId) }
    }

    public func createTreatmentLocalization(treatmentId: String, locale: String) async throws -> ASCKit.ExperimentTreatmentLocalization {
        let body = AppStoreVersionExperimentTreatmentLocalizationCreateRequest(data: .init(
            type: .appStoreVersionExperimentTreatmentLocalizations,
            attributes: .init(locale: locale),
            relationships: .init(
                appStoreVersionExperimentTreatment: .init(data: .init(type: .appStoreVersionExperimentTreatments, id: treatmentId))
            )
        ))
        let response = try await client.request(APIEndpoint.v1.appStoreVersionExperimentTreatmentLocalizations.post(body))
        return mapLocalization(response.data, treatmentId: treatmentId)
    }

    public func deleteTreatmentLocalization(localizationId: String) async throws {
        _ = try await client.request(APIEndpoint.v1.appStoreVersionExperimentTreatmentLocalizations.id(localizationId).delete)
    }

    // MARK: - Mappers

    private func mapExperiment(
        _ sdk: AppStoreConnect_Swift_SDK.AppStoreVersionExperimentV2,
        appId: String
    ) -> ASCKit.AppStoreVersionExperiment {
        let platform = sdk.attributes?.platform.flatMap { ASCKit.AppStorePlatform(rawValue: $0.rawValue) } ?? .iOS
        let state = sdk.attributes?.state.flatMap { ASCKit.AppStoreVersionExperimentState(rawValue: $0.rawValue) } ?? .prepareForSubmission
        return ASCKit.AppStoreVersionExperiment(
            id: sdk.id,
            appId: appId,
            name: sdk.attributes?.name ?? "",
            platform: platform,
            trafficProportion: sdk.attributes?.trafficProportion ?? 0,
            state: state,
            isReviewRequired: sdk.attributes?.isReviewRequired ?? true,
            startDate: sdk.attributes?.startDate.map(Self.iso8601),
            endDate: sdk.attributes?.endDate.map(Self.iso8601),
            latestControlVersionId: sdk.relationships?.latestControlVersion?.data?.id
        )
    }

    private func mapTreatment(
        _ sdk: AppStoreConnect_Swift_SDK.AppStoreVersionExperimentTreatment,
        experimentId: String
    ) -> ASCKit.ExperimentTreatment {
        ASCKit.ExperimentTreatment(
            id: sdk.id,
            experimentId: experimentId,
            name: sdk.attributes?.name ?? "",
            appIconName: sdk.attributes?.appIconName,
            promotedDate: sdk.attributes?.promotedDate.map(Self.iso8601)
        )
    }

    private func mapLocalization(
        _ sdk: AppStoreConnect_Swift_SDK.AppStoreVersionExperimentTreatmentLocalization,
        treatmentId: String
    ) -> ASCKit.ExperimentTreatmentLocalization {
        ASCKit.ExperimentTreatmentLocalization(
            id: sdk.id,
            treatmentId: treatmentId,
            locale: sdk.attributes?.locale ?? ""
        )
    }

    private static func iso8601(_ date: Date) -> String {
        ISO8601DateFormatter().string(from: date)
    }
}
