@preconcurrency import AppStoreConnect_Swift_SDK
import Domain

public struct SDKScreenshotRepository: ScreenshotRepository, @unchecked Sendable {
    private let provider: APIProvider

    public init(provider: APIProvider) {
        self.provider = provider
    }

    public func listScreenshotSets(localizationId: String) async throws -> [Domain.AppScreenshotSet] {
        let request = APIEndpoint.v1.appStoreVersionLocalizations.id(localizationId).appScreenshotSets.get()
        let response = try await provider.request(request)
        return response.data.map { mapScreenshotSet($0) }
    }

    public func listScreenshotSets(appId: String) async throws -> [Domain.AppScreenshotSet] {
        // Fetch all platform versions (iOS, macOS, tvOS, watchOS, visionOS may each be separate)
        let versionsRequest = APIEndpoint.v1.apps.id(appId).appStoreVersions.get()
        let versionsResponse = try await provider.request(versionsRequest)
        guard !versionsResponse.data.isEmpty else { return [] }

        // For each platform version, get its first localization and collect all screenshot sets
        var allSets: [Domain.AppScreenshotSet] = []
        for version in versionsResponse.data {
            let locRequest = APIEndpoint.v1.appStoreVersions.id(version.id).appStoreVersionLocalizations.get(
                parameters: .init(limit: 1)
            )
            guard let locResponse = try? await provider.request(locRequest),
                  let locId = locResponse.data.first?.id else { continue }

            let sets = try await listScreenshotSets(localizationId: locId)
            allSets.append(contentsOf: sets)
        }
        return allSets
    }

    public func listScreenshots(setId: String) async throws -> [Domain.AppScreenshot] {
        let request = APIEndpoint.v1.appScreenshotSets.id(setId).appScreenshots.get()
        let response = try await provider.request(request)
        return response.data.map { mapScreenshot($0) }
    }

    private func mapScreenshotSet(
        _ sdkSet: AppStoreConnect_Swift_SDK.AppScreenshotSet
    ) -> Domain.AppScreenshotSet {
        let displayType = Domain.ScreenshotDisplayType(
            rawValue: sdkSet.attributes?.screenshotDisplayType?.rawValue ?? ""
        ) ?? .iphone67
        let count = sdkSet.relationships?.appScreenshots?.data?.count ?? 0
        return Domain.AppScreenshotSet(
            id: sdkSet.id,
            screenshotDisplayType: displayType,
            screenshotsCount: count
        )
    }

    private func mapScreenshot(
        _ sdkScreenshot: AppStoreConnect_Swift_SDK.AppScreenshot
    ) -> Domain.AppScreenshot {
        let state = mapAssetState(sdkScreenshot.attributes?.assetDeliveryState?.state)
        return Domain.AppScreenshot(
            id: sdkScreenshot.id,
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
