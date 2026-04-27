@preconcurrency import AppStoreConnect_Swift_SDK
import Domain
import Foundation

public struct SDKSubscriptionReviewRepository: SubscriptionReviewRepository, @unchecked Sendable {
    private let client: any APIClient

    public init(client: any APIClient) {
        self.client = client
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

        let md5 = fileData.md5HexString
        let confirmBody = SubscriptionAppStoreReviewScreenshotUpdateRequest(data: .init(
            type: .subscriptionAppStoreReviewScreenshots,
            id: screenshotId,
            attributes: .init(sourceFileChecksum: md5, isUploaded: true)
        ))
        let confirmed = try await client.request(
            APIEndpoint.v1.subscriptionAppStoreReviewScreenshots.id(screenshotId).patch(confirmBody)
        )
        return mapReviewScreenshot(confirmed.data, subscriptionId: subscriptionId)
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

        let md5 = fileData.md5HexString
        let confirmBody = SubscriptionImageUpdateRequest(data: .init(
            type: .subscriptionImages,
            id: imageId,
            attributes: .init(sourceFileChecksum: md5, isUploaded: true)
        ))
        let confirmed = try await client.request(APIEndpoint.v1.subscriptionImages.id(imageId).patch(confirmBody))
        return mapImage(confirmed.data, subscriptionId: subscriptionId)
    }

    public func deleteImage(imageId: String) async throws {
        _ = try await client.request(APIEndpoint.v1.subscriptionImages.id(imageId).delete)
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
            state: state
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
            assetState: state
        )
    }
}
