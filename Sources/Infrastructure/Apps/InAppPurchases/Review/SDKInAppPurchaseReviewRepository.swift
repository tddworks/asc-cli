@preconcurrency import AppStoreConnect_Swift_SDK
import Domain
import Foundation

public struct SDKInAppPurchaseReviewRepository: InAppPurchaseReviewRepository, @unchecked Sendable {
    private let client: any APIClient
    /// Per-attempt sleep when polling for `imageAsset` readiness post-upload.
    /// Mirrors the iOS SDK's 2s default; tests override to 0 to keep the suite fast.
    private let pollDelayNanos: UInt64
    /// Max attempts before falling back to the latest state (mapper drops empty
    /// `imageAsset`, so callers see `imageAsset == nil` rather than zero values).
    private let pollMaxAttempts: Int

    public init(
        client: any APIClient,
        pollDelayNanos: UInt64 = 2_000_000_000,
        pollMaxAttempts: Int = 15
    ) {
        self.client = client
        self.pollDelayNanos = pollDelayNanos
        self.pollMaxAttempts = pollMaxAttempts
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
        _ = try await client.request(
            APIEndpoint.v1.inAppPurchaseAppStoreReviewScreenshots.id(screenshotId).patch(confirmBody)
        )

        // Step 4: Poll until ASC finishes processing — the PATCH-commit response
        // returns an empty `imageAsset` (templateURL/width/height all zero/empty)
        // because processing is async. Mirrors the iOS SDK's verifyReviewScreenshotUpload.
        return try await pollReviewScreenshotReady(screenshotId: screenshotId, iapId: iapId)
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
        _ = try await client.request(APIEndpoint.v1.inAppPurchaseImages.id(imageId).patch(confirmBody))

        // Step 4: Poll until ASC finishes processing — see `uploadReviewScreenshot`.
        return try await pollImageReady(imageId: imageId, iapId: iapId)
    }

    public func deleteImage(imageId: String) async throws {
        _ = try await client.request(APIEndpoint.v1.inAppPurchaseImages.id(imageId).delete)
    }

    // MARK: - Poll for upload readiness

    /// Re-fetches the screenshot until ASC reports `assetDeliveryState == COMPLETE`
    /// (imageAsset URL populated). Stops on `FAILED`. Falls back to whatever the latest
    /// fetch returned if processing exceeds `pollMaxAttempts × pollDelayNanos`.
    private func pollReviewScreenshotReady(screenshotId: String, iapId: String) async throws -> Domain.InAppPurchaseReviewScreenshot {
        var latest: Domain.InAppPurchaseReviewScreenshot?
        for attempt in 1...pollMaxAttempts {
            let response = try await client.request(
                APIEndpoint.v1.inAppPurchaseAppStoreReviewScreenshots.id(screenshotId).get()
            )
            latest = mapReviewScreenshot(response.data, iapId: iapId)

            let stateRaw = response.data.attributes?.assetDeliveryState?.state?.rawValue
            switch stateRaw {
            case "COMPLETE":
                return latest!
            case "FAILED":
                let errors = response.data.attributes?.assetDeliveryState?.errors?
                    .compactMap(\.description).joined(separator: ", ") ?? "Unknown error"
                throw APIError.unknown("Review screenshot processing failed: \(errors)")
            default:
                if attempt < pollMaxAttempts {
                    try await Task.sleep(nanoseconds: pollDelayNanos)
                }
            }
        }
        return latest ?? mapReviewScreenshot(.init(type: .inAppPurchaseAppStoreReviewScreenshots, id: screenshotId), iapId: iapId)
    }

    /// Re-fetches the image until state is one of `PREPARE_FOR_SUBMISSION /
    /// WAITING_FOR_REVIEW / APPROVED` (imageAsset URL populated). Stops on `FAILED`/`REJECTED`.
    private func pollImageReady(imageId: String, iapId: String) async throws -> Domain.InAppPurchasePromotionalImage {
        var latest: Domain.InAppPurchasePromotionalImage?
        for attempt in 1...pollMaxAttempts {
            let response = try await client.request(
                APIEndpoint.v1.inAppPurchaseImages.id(imageId).get()
            )
            latest = mapImage(response.data, iapId: iapId)

            switch response.data.attributes?.state {
            case .prepareForSubmission, .waitingForReview, .approved:
                return latest!
            case .failed, .rejected:
                throw APIError.unknown("Image processing failed with state: \(response.data.attributes?.state?.rawValue ?? "unknown")")
            default:
                if attempt < pollMaxAttempts {
                    try await Task.sleep(nanoseconds: pollDelayNanos)
                }
            }
        }
        return latest ?? mapImage(.init(type: .inAppPurchaseImages, id: imageId), iapId: iapId)
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

    private func mapImageAsset(_ sdk: AppStoreConnect_Swift_SDK.ImageAsset?) -> Domain.ImageAsset? {
        guard let templateUrl = sdk?.templateURL, !templateUrl.isEmpty,
              let width = sdk?.width, width > 0,
              let height = sdk?.height, height > 0
        else { return nil }
        return Domain.ImageAsset(templateUrl: templateUrl, width: width, height: height)
    }
}
