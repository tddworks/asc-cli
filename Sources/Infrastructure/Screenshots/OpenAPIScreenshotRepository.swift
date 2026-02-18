@preconcurrency import AppStoreConnect_Swift_SDK
import Domain

public struct SDKScreenshotRepository: ScreenshotRepository, @unchecked Sendable {
    private let client: any APIClient

    public init(client: any APIClient) {
        self.client = client
    }

    public func listLocalizations(versionId: String) async throws -> [Domain.AppStoreVersionLocalization] {
        let request = APIEndpoint.v1.appStoreVersions.id(versionId).appStoreVersionLocalizations.get()
        let response = try await client.request(request)
        return response.data.map { mapLocalization($0, versionId: versionId) }
    }

    public func listScreenshotSets(localizationId: String) async throws -> [Domain.AppScreenshotSet] {
        let request = APIEndpoint.v1.appStoreVersionLocalizations.id(localizationId).appScreenshotSets.get()
        let response = try await client.request(request)
        return response.data.map { mapScreenshotSet($0, localizationId: localizationId) }
    }

    public func listScreenshots(setId: String) async throws -> [Domain.AppScreenshot] {
        let request = APIEndpoint.v1.appScreenshotSets.id(setId).appScreenshots.get()
        let response = try await client.request(request)
        return response.data.map { mapScreenshot($0, setId: setId) }
    }

    private func mapLocalization(
        _ sdkLoc: AppStoreConnect_Swift_SDK.AppStoreVersionLocalization,
        versionId: String
    ) -> Domain.AppStoreVersionLocalization {
        Domain.AppStoreVersionLocalization(
            id: sdkLoc.id,
            versionId: versionId,
            locale: sdkLoc.attributes?.locale ?? ""
        )
    }

    private func mapScreenshotSet(
        _ sdkSet: AppStoreConnect_Swift_SDK.AppScreenshotSet,
        localizationId: String
    ) -> Domain.AppScreenshotSet {
        let displayType = Domain.ScreenshotDisplayType(
            rawValue: sdkSet.attributes?.screenshotDisplayType?.rawValue ?? ""
        ) ?? .iphone67
        let count = sdkSet.relationships?.appScreenshots?.data?.count ?? 0
        return Domain.AppScreenshotSet(
            id: sdkSet.id,
            localizationId: localizationId,
            screenshotDisplayType: displayType,
            screenshotsCount: count
        )
    }

    private func mapScreenshot(
        _ sdkScreenshot: AppStoreConnect_Swift_SDK.AppScreenshot,
        setId: String
    ) -> Domain.AppScreenshot {
        let state = mapAssetState(sdkScreenshot.attributes?.assetDeliveryState?.state)
        return Domain.AppScreenshot(
            id: sdkScreenshot.id,
            setId: setId,
            fileName: sdkScreenshot.attributes?.fileName ?? "",
            fileSize: sdkScreenshot.attributes?.fileSize ?? 0,
            assetState: state,
            imageWidth: sdkScreenshot.attributes?.imageAsset?.width,
            imageHeight: sdkScreenshot.attributes?.imageAsset?.height
        )
    }

    private func mapAssetState(
        _ state: AppStoreConnect_Swift_SDK.AppMediaAssetState.State?
    ) -> Domain.AppScreenshot.AssetDeliveryState? {
        guard let state else { return nil }
        switch state {
        case .awaitingUpload: return .awaitingUpload
        case .uploadComplete: return .uploadComplete
        case .complete: return .complete
        case .failed: return .failed
        }
    }
}
