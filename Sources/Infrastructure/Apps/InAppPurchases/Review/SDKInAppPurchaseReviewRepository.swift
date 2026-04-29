@preconcurrency import AppStoreConnect_Swift_SDK
import Domain
import Foundation

public struct SDKInAppPurchaseReviewRepository: InAppPurchaseReviewRepository, @unchecked Sendable {
    private let client: any APIClient

    public init(client: any APIClient) {
        self.client = client
    }

    // MARK: - Review Screenshot

    public func getReviewScreenshot(iapId: String) async throws -> Domain.InAppPurchaseReviewScreenshot? {
        do {
            let response = try await client.request(
                APIEndpoint.v2.inAppPurchases.id(iapId).appStoreReviewScreenshot.get()
            )
            return mapReviewScreenshot(response.data, iapId: iapId)
        } catch {
            // Treat 404 as "no screenshot uploaded"
            return nil
        }
    }

    public func uploadReviewScreenshot(
        iapId: String,
        fileURL: URL
    ) async throws -> Domain.InAppPurchaseReviewScreenshot {
        let fileData = try Data(contentsOf: fileURL)
        let fileName = fileURL.lastPathComponent

        // Step 1: Reserve
        let reserveBody = InAppPurchaseAppStoreReviewScreenshotCreateRequest(data: .init(
            type: .inAppPurchaseAppStoreReviewScreenshots,
            attributes: .init(fileSize: fileData.count, fileName: fileName),
            relationships: .init(
                inAppPurchaseV2: .init(data: .init(type: .inAppPurchases, id: iapId))
            )
        ))
        let reserved = try await client.request(
            APIEndpoint.v1.inAppPurchaseAppStoreReviewScreenshots.post(reserveBody)
        )
        let screenshotId = reserved.data.id
        let uploadOps = reserved.data.attributes?.uploadOperations ?? []

        // Step 2: Upload chunks
        try await uploadChunks(uploadOps: uploadOps, fileData: fileData)

        // Step 3: Commit with MD5
        let md5 = fileData.md5HexString
        let confirmBody = InAppPurchaseAppStoreReviewScreenshotUpdateRequest(data: .init(
            type: .inAppPurchaseAppStoreReviewScreenshots,
            id: screenshotId,
            attributes: .init(sourceFileChecksum: md5, isUploaded: true)
        ))
        let confirmed = try await client.request(
            APIEndpoint.v1.inAppPurchaseAppStoreReviewScreenshots.id(screenshotId).patch(confirmBody)
        )
        return mapReviewScreenshot(confirmed.data, iapId: iapId)
    }

    public func deleteReviewScreenshot(screenshotId: String) async throws {
        _ = try await client.request(
            APIEndpoint.v1.inAppPurchaseAppStoreReviewScreenshots.id(screenshotId).delete
        )
    }

    // MARK: - Promotional Images

    public func listImages(iapId: String) async throws -> [Domain.InAppPurchasePromotionalImage] {
        let request = APIEndpoint.v2.inAppPurchases.id(iapId).images.get()
        let response = try await client.request(request)
        return response.data.map { mapImage($0, iapId: iapId) }
    }

    public func uploadImage(iapId: String, fileURL: URL) async throws -> Domain.InAppPurchasePromotionalImage {
        let fileData = try Data(contentsOf: fileURL)
        let fileName = fileURL.lastPathComponent

        let reserveBody = InAppPurchaseImageCreateRequest(data: .init(
            type: .inAppPurchaseImages,
            attributes: .init(fileSize: fileData.count, fileName: fileName),
            relationships: .init(
                inAppPurchase: .init(data: .init(type: .inAppPurchases, id: iapId))
            )
        ))
        let reserved = try await client.request(APIEndpoint.v1.inAppPurchaseImages.post(reserveBody))
        let imageId = reserved.data.id
        let uploadOps = reserved.data.attributes?.uploadOperations ?? []

        try await uploadChunks(uploadOps: uploadOps, fileData: fileData)

        let md5 = fileData.md5HexString
        let confirmBody = InAppPurchaseImageUpdateRequest(data: .init(
            type: .inAppPurchaseImages,
            id: imageId,
            attributes: .init(sourceFileChecksum: md5, isUploaded: true)
        ))
        let confirmed = try await client.request(APIEndpoint.v1.inAppPurchaseImages.id(imageId).patch(confirmBody))
        return mapImage(confirmed.data, iapId: iapId)
    }

    public func deleteImage(imageId: String) async throws {
        _ = try await client.request(APIEndpoint.v1.inAppPurchaseImages.id(imageId).delete)
    }

    // MARK: - Helpers

    private func uploadChunks(uploadOps: [UploadOperation], fileData: Data) async throws {
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
    }

    private func mapReviewScreenshot(
        _ sdk: AppStoreConnect_Swift_SDK.InAppPurchaseAppStoreReviewScreenshot,
        iapId: String
    ) -> Domain.InAppPurchaseReviewScreenshot {
        let stateRaw = sdk.attributes?.assetDeliveryState?.state?.rawValue
        let state = stateRaw.flatMap { Domain.InAppPurchaseReviewScreenshot.AssetState(rawValue: $0) }
        return Domain.InAppPurchaseReviewScreenshot(
            id: sdk.id,
            iapId: iapId,
            fileName: sdk.attributes?.fileName ?? "",
            fileSize: sdk.attributes?.fileSize ?? 0,
            assetState: state,
            imageAsset: mapImageAsset(sdk.attributes?.imageAsset)
        )
    }

    private func mapImage(
        _ sdk: AppStoreConnect_Swift_SDK.InAppPurchaseImage,
        iapId: String
    ) -> Domain.InAppPurchasePromotionalImage {
        let stateRaw = sdk.attributes?.state?.rawValue
        let state = stateRaw.flatMap { Domain.InAppPurchasePromotionalImage.ImageState(rawValue: $0) }
        return Domain.InAppPurchasePromotionalImage(
            id: sdk.id,
            iapId: iapId,
            fileName: sdk.attributes?.fileName ?? "",
            fileSize: sdk.attributes?.fileSize ?? 0,
            state: state,
            imageAsset: mapImageAsset(sdk.attributes?.imageAsset)
        )
    }

    /// ASC returns a non-nil `imageAsset` with empty `templateURL`/zero dimensions
    /// immediately after the upload commit but before server-side processing finishes.
    /// We treat that not-yet-processed shape as absent so JSON output omits the field
    /// (frontends keep showing a local preview and poll the GET endpoint until the
    /// asset is populated). Mirrors how the iOS app's `previewImageURL` returns nil
    /// for an empty `templateURL`.
    private func mapImageAsset(_ sdk: AppStoreConnect_Swift_SDK.ImageAsset?) -> Domain.ImageAsset? {
        guard let templateUrl = sdk?.templateURL, !templateUrl.isEmpty,
              let width = sdk?.width, width > 0,
              let height = sdk?.height, height > 0
        else { return nil }
        return Domain.ImageAsset(templateUrl: templateUrl, width: width, height: height)
    }
}
