@preconcurrency import AppStoreConnect_Swift_SDK
import CryptoKit
import Domain
import Foundation

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

    public func createLocalization(versionId: String, locale: String) async throws -> Domain.AppStoreVersionLocalization {
        let body = AppStoreVersionLocalizationCreateRequest(
            data: .init(
                type: .appStoreVersionLocalizations,
                attributes: .init(locale: locale),
                relationships: .init(appStoreVersion: .init(data: .init(type: .appStoreVersions, id: versionId)))
            )
        )
        let response = try await client.request(APIEndpoint.v1.appStoreVersionLocalizations.post(body))
        return mapLocalization(response.data, versionId: versionId)
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
        for op in uploadOps {
            guard let urlString = op.url, let url = URL(string: urlString),
                  let offset = op.offset, let length = op.length else { continue }
            let chunk = fileData.subdata(in: offset..<(offset + length))
            var request = URLRequest(url: url)
            request.httpMethod = op.method ?? "PUT"
            request.httpBody = chunk
            for header in op.requestHeaders ?? [] {
                if let name = header.name, let value = header.value {
                    request.setValue(value, forHTTPHeaderField: name)
                }
            }
            _ = try await URLSession.shared.data(for: request)
        }

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

private extension Data {
    var md5HexString: String {
        let digest = Insecure.MD5.hash(data: self)
        return digest.map { String(format: "%02x", $0) }.joined()
    }
}
