@preconcurrency import AppStoreConnect_Swift_SDK
import Domain
import Foundation

public struct SDKSubscriptionReviewRepository: SubscriptionReviewRepository, @unchecked Sendable {
    private let client: any APIClient
    /// Per-attempt sleep when polling for `imageAsset` readiness post-upload.
    /// Mirrors the iOS SDK's 2s default; tests override to 0 to keep the suite fast.
    private let pollDelayNanos: UInt64
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

    public func getReviewScreenshot(subscriptionId: String) async throws -> Domain.SubscriptionReviewScreenshot? {
        do {
            let response = try await client.request(
                APIEndpoint.v1.subscriptions.id(subscriptionId).appStoreReviewScreenshot.get()
            )
            return mapReviewScreenshot(response.data, subscriptionId: subscriptionId)
        } catch {
            return nil
        }
    }

    public func uploadReviewScreenshot(
        subscriptionId: String,
        fileURL: URL
    ) async throws -> Domain.SubscriptionReviewScreenshot {
        let fileData = try Data(contentsOf: fileURL)
        let fileName = fileURL.lastPathComponent

        let reserveBody = SubscriptionAppStoreReviewScreenshotCreateRequest(data: .init(
            type: .subscriptionAppStoreReviewScreenshots,
            attributes: .init(fileSize: fileData.count, fileName: fileName),
            relationships: .init(
                subscription: .init(data: .init(type: .subscriptions, id: subscriptionId))
            )
        ))
        let reserved = try await client.request(
            APIEndpoint.v1.subscriptionAppStoreReviewScreenshots.post(reserveBody)
        )
        let screenshotId = reserved.data.id
        let uploadOps = reserved.data.attributes?.uploadOperations ?? []

        try await uploadChunks(uploadOps: uploadOps, fileData: fileData)

        let md5 = fileData.md5HexString
        let confirmBody = SubscriptionAppStoreReviewScreenshotUpdateRequest(data: .init(
            type: .subscriptionAppStoreReviewScreenshots,
            id: screenshotId,
            attributes: .init(sourceFileChecksum: md5, isUploaded: true)
        ))
        _ = try await client.request(
            APIEndpoint.v1.subscriptionAppStoreReviewScreenshots.id(screenshotId).patch(confirmBody)
        )

        // Step 4: Poll until ASC finishes processing the screenshot — the PATCH-commit
        // response returns an empty `imageAsset` because processing is async. Mirrors
        // the iOS SDK's verifyReviewScreenshotUpload.
        return try await pollReviewScreenshotReady(screenshotId: screenshotId, subscriptionId: subscriptionId)
    }

    public func deleteReviewScreenshot(screenshotId: String) async throws {
        _ = try await client.request(
            APIEndpoint.v1.subscriptionAppStoreReviewScreenshots.id(screenshotId).delete
        )
    }

    // MARK: - Promotional Images

    public func listImages(subscriptionId: String) async throws -> [Domain.SubscriptionPromotionalImage] {
        let request = APIEndpoint.v1.subscriptions.id(subscriptionId).images.get()
        let response = try await client.request(request)
        return response.data.map { mapImage($0, subscriptionId: subscriptionId) }
    }

    public func uploadImage(subscriptionId: String, fileURL: URL) async throws -> Domain.SubscriptionPromotionalImage {
        let fileData = try Data(contentsOf: fileURL)
        let fileName = fileURL.lastPathComponent

        let reserveBody = SubscriptionImageCreateRequest(data: .init(
            type: .subscriptionImages,
            attributes: .init(fileSize: fileData.count, fileName: fileName),
            relationships: .init(
                subscription: .init(data: .init(type: .subscriptions, id: subscriptionId))
            )
        ))
        let reserved = try await client.request(APIEndpoint.v1.subscriptionImages.post(reserveBody))
        let imageId = reserved.data.id
        let uploadOps = reserved.data.attributes?.uploadOperations ?? []

        try await uploadChunks(uploadOps: uploadOps, fileData: fileData)

        let md5 = fileData.md5HexString
        let confirmBody = SubscriptionImageUpdateRequest(data: .init(
            type: .subscriptionImages,
            id: imageId,
            attributes: .init(sourceFileChecksum: md5, isUploaded: true)
        ))
        _ = try await client.request(APIEndpoint.v1.subscriptionImages.id(imageId).patch(confirmBody))

        // Step 4: Poll until ASC finishes processing — see `uploadReviewScreenshot`.
        return try await pollImageReady(imageId: imageId, subscriptionId: subscriptionId)
    }

    public func deleteImage(imageId: String) async throws {
        _ = try await client.request(APIEndpoint.v1.subscriptionImages.id(imageId).delete)
    }

    /// Mirrors `AppStoreConnectInAppPurchaseRepository.uploadChunks` in `AppStoreSdk-SPM`.
    /// See the IAP repo's twin for rationale.
    private func uploadChunks(uploadOps: [UploadOperation], fileData: Data) async throws {
        for operation in uploadOps {
            guard let urlString = operation.url,
                  let url = URL(string: urlString),
                  let method = operation.method,
                  let offset = operation.offset,
                  let length = operation.length
            else { continue }

            let chunk = fileData[offset..<(offset + length)]
            var request = URLRequest(url: url)
            request.httpMethod = method
            for header in (operation.requestHeaders ?? []) {
                if let name = header.name {
                    request.setValue(header.value, forHTTPHeaderField: name)
                }
            }
            request.httpBody = chunk

            let (_, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse,
                  200..<300 ~= httpResponse.statusCode
            else {
                throw APIError.unknown("Image upload chunk failed")
            }
        }
    }

    // MARK: - Poll for upload readiness

    /// Re-fetches the screenshot until ASC reports `assetDeliveryState == COMPLETE`
    /// (imageAsset URL populated). Stops on `FAILED`. Falls back to whatever the latest
    /// fetch returned if processing exceeds `pollMaxAttempts × pollDelayNanos`.
    private func pollReviewScreenshotReady(screenshotId: String, subscriptionId: String) async throws -> Domain.SubscriptionReviewScreenshot {
        var latest: Domain.SubscriptionReviewScreenshot?
        for attempt in 1...pollMaxAttempts {
            let response = try await client.request(
                APIEndpoint.v1.subscriptionAppStoreReviewScreenshots.id(screenshotId).get()
            )
            latest = mapReviewScreenshot(response.data, subscriptionId: subscriptionId)

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
        return latest ?? mapReviewScreenshot(.init(type: .subscriptionAppStoreReviewScreenshots, id: screenshotId), subscriptionId: subscriptionId)
    }

    /// Re-fetches the image until state is one of `PREPARE_FOR_SUBMISSION /
    /// WAITING_FOR_REVIEW / APPROVED` (imageAsset URL populated). Stops on `FAILED`/`REJECTED`.
    private func pollImageReady(imageId: String, subscriptionId: String) async throws -> Domain.SubscriptionPromotionalImage {
        var latest: Domain.SubscriptionPromotionalImage?
        for attempt in 1...pollMaxAttempts {
            let response = try await client.request(
                APIEndpoint.v1.subscriptionImages.id(imageId).get()
            )
            latest = mapImage(response.data, subscriptionId: subscriptionId)

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
        return latest ?? mapImage(.init(type: .subscriptionImages, id: imageId), subscriptionId: subscriptionId)
    }

    private func mapImage(
        _ sdk: AppStoreConnect_Swift_SDK.SubscriptionImage,
        subscriptionId: String
    ) -> Domain.SubscriptionPromotionalImage {
        let stateRaw = sdk.attributes?.state?.rawValue
        let state = stateRaw.flatMap { Domain.SubscriptionPromotionalImage.ImageState(rawValue: $0) }
        return Domain.SubscriptionPromotionalImage(
            id: sdk.id,
            subscriptionId: subscriptionId,
            fileName: sdk.attributes?.fileName ?? "",
            fileSize: sdk.attributes?.fileSize ?? 0,
            state: state,
            imageAsset: mapImageAsset(sdk.attributes?.imageAsset)
        )
    }

    private func mapReviewScreenshot(
        _ sdk: AppStoreConnect_Swift_SDK.SubscriptionAppStoreReviewScreenshot,
        subscriptionId: String
    ) -> Domain.SubscriptionReviewScreenshot {
        let stateRaw = sdk.attributes?.assetDeliveryState?.state?.rawValue
        let state = stateRaw.flatMap { Domain.SubscriptionReviewScreenshot.AssetState(rawValue: $0) }
        return Domain.SubscriptionReviewScreenshot(
            id: sdk.id,
            subscriptionId: subscriptionId,
            fileName: sdk.attributes?.fileName ?? "",
            fileSize: sdk.attributes?.fileSize ?? 0,
            assetState: state,
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
