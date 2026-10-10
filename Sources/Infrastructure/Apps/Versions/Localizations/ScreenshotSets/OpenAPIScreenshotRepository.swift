@preconcurrency import AppStoreConnect_Swift_SDK
import Domain
import Foundation

public struct SDKScreenshotRepository: ScreenshotRepository, @unchecked Sendable {
    private let client: any APIClient
    private let uploader: UploadOperationsExecutor

    public init(client: any APIClient, uploader: UploadOperationsExecutor = UploadOperationsExecutor()) {
        self.client = client
        self.uploader = uploader
    }

    public func listScreenshotSets(localizationId: String) async throws -> [Domain.AppScreenshotSet] {
        let request = APIEndpoint.v1.appStoreVersionLocalizations.id(localizationId).appScreenshotSets.get(
            parameters: .init(include: [.appScreenshots])
        )
        let response = try await client.request(request)
        return response.data.map { mapScreenshotSet($0, localizationId: localizationId) }
    }

    public func listScreenshots(setId: String) async throws -> [Domain.AppScreenshot] {
        let request = APIEndpoint.v1.appScreenshotSets.id(setId).appScreenshots.get()
        let response = try await client.request(request)
        return response.data.map { mapScreenshot($0, setId: setId) }
    }

    public func createScreenshotSet(localizationId: String, displayType: Domain.ScreenshotDisplayType) async throws -> Domain.AppScreenshotSet {
        guard let sdkDisplayType = AppStoreConnect_Swift_SDK.ScreenshotDisplayType(rawValue: displayType.rawValue) else {
            throw Domain.APIError.unknown("Unsupported display type: \(displayType.rawValue)")
        }
        let body = AppScreenshotSetCreateRequest(
            data: .init(
                type: .appScreenshotSets,
                attributes: .init(screenshotDisplayType: sdkDisplayType),
                relationships: .init(
                    appStoreVersionLocalization: .init(data: .init(type: .appStoreVersionLocalizations, id: localizationId))
                )
            )
        )
        let response = try await client.request(APIEndpoint.v1.appScreenshotSets.post(body))
        return mapScreenshotSet(response.data, localizationId: localizationId)
    }

    public func uploadScreenshot(setId: String, fileURL: URL) async throws -> Domain.AppScreenshot {
        let fileData = try Data(contentsOf: fileURL)
        let fileName = fileURL.lastPathComponent
        let fileSize = fileData.count

        // Step 1: Reserve screenshot slot
        let reserveBody = AppScreenshotCreateRequest(
            data: .init(
                type: .appScreenshots,
                attributes: .init(fileSize: fileSize, fileName: fileName),
                relationships: .init(appScreenshotSet: .init(data: .init(type: .appScreenshotSets, id: setId)))
            )
        )
        let reserved = try await client.request(APIEndpoint.v1.appScreenshots.post(reserveBody))
        let screenshotId = reserved.data.id
        let uploadOps = reserved.data.attributes?.uploadOperations ?? []

        // Step 2: Upload image data via each upload operation
        try await uploader.upload(fileURL: fileURL, operations: uploadOps)

        // Step 3: Confirm upload
        let md5 = fileData.md5HexString
        let confirmBody = AppScreenshotUpdateRequest(
            data: .init(
                type: .appScreenshots,
                id: screenshotId,
                attributes: .init(sourceFileChecksum: md5, isUploaded: true)
            )
        )
        let confirmed = try await client.request(APIEndpoint.v1.appScreenshots.id(screenshotId).patch(confirmBody))
        return mapScreenshot(confirmed.data, setId: setId)
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
            screenshotsCount: count,
            repo: self
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
            imageHeight: sdkScreenshot.attributes?.imageAsset?.height,
            sourceUrl: sdkScreenshot.attributes?.imageAsset?.templateURL
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
