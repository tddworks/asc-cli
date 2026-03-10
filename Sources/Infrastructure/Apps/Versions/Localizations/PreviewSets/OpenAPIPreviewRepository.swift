@preconcurrency import AppStoreConnect_Swift_SDK
import Domain
import Foundation

public struct OpenAPIPreviewRepository: PreviewRepository, @unchecked Sendable {
    private let client: any APIClient

    public init(client: any APIClient) {
        self.client = client
    }

    public func listPreviewSets(localizationId: String) async throws -> [Domain.AppPreviewSet] {
        let request = APIEndpoint.v1.appStoreVersionLocalizations.id(localizationId).appPreviewSets.get(
            parameters: .init(include: [.appPreviews])
        )
        let response = try await client.request(request)
        return response.data.map { mapPreviewSet($0, localizationId: localizationId) }
    }

    public func createPreviewSet(localizationId: String, previewType: Domain.PreviewType) async throws -> Domain.AppPreviewSet {
        guard let sdkPreviewType = AppStoreConnect_Swift_SDK.PreviewType(rawValue: previewType.rawValue) else {
            throw Domain.APIError.unknown("Unsupported preview type: \(previewType.rawValue)")
        }
        let body = AppPreviewSetCreateRequest(
            data: .init(
                type: .appPreviewSets,
                attributes: .init(previewType: sdkPreviewType),
                relationships: .init(
                    appStoreVersionLocalization: .init(
                        data: .init(type: .appStoreVersionLocalizations, id: localizationId)
                    )
                )
            )
        )
        let response = try await client.request(APIEndpoint.v1.appPreviewSets.post(body))
        return mapPreviewSet(response.data, localizationId: localizationId)
    }

    public func listPreviews(setId: String) async throws -> [Domain.AppPreview] {
        let request = APIEndpoint.v1.appPreviewSets.id(setId).appPreviews.get()
        let response = try await client.request(request)
        return response.data.map { mapPreview($0, setId: setId) }
    }

    public func uploadPreview(setId: String, fileURL: URL, previewFrameTimeCode: String?) async throws -> Domain.AppPreview {
        let fileData = try Data(contentsOf: fileURL)
        let fileName = fileURL.lastPathComponent
        let fileSize = fileData.count
        let mimeType = mimeTypeForFileName(fileName)

        // Step 1: Reserve preview slot
        let reserveBody = AppPreviewCreateRequest(
            data: .init(
                type: .appPreviews,
                attributes: .init(
                    fileSize: fileSize,
                    fileName: fileName,
                    previewFrameTimeCode: previewFrameTimeCode,
                    mimeType: mimeType
                ),
                relationships: .init(
                    appPreviewSet: .init(data: .init(type: .appPreviewSets, id: setId))
                )
            )
        )
        let reserved = try await client.request(APIEndpoint.v1.appPreviews.post(reserveBody))
        let previewId = reserved.data.id
        let uploadOps = reserved.data.attributes?.uploadOperations ?? []

        // Step 2: Upload video data via each upload operation
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

        // Step 3: Confirm upload with MD5 checksum
        let md5 = fileData.md5HexString
        let confirmBody = AppPreviewUpdateRequest(
            data: .init(
                type: .appPreviews,
                id: previewId,
                attributes: .init(sourceFileChecksum: md5, isUploaded: true)
            )
        )
        let confirmed = try await client.request(APIEndpoint.v1.appPreviews.id(previewId).patch(confirmBody))
        return mapPreview(confirmed.data, setId: setId)
    }

    // MARK: - Mappers (inject parent IDs)

    private func mapPreviewSet(
        _ sdkSet: AppStoreConnect_Swift_SDK.AppPreviewSet,
        localizationId: String
    ) -> Domain.AppPreviewSet {
        let previewType = Domain.PreviewType(rawValue: sdkSet.attributes?.previewType?.rawValue ?? "") ?? .iphone67
        let count = sdkSet.relationships?.appPreviews?.data?.count ?? 0
        return Domain.AppPreviewSet(
            id: sdkSet.id,
            localizationId: localizationId,
            previewType: previewType,
            previewsCount: count
        )
    }

    private func mapPreview(
        _ sdkPreview: AppStoreConnect_Swift_SDK.AppPreview,
        setId: String
    ) -> Domain.AppPreview {
        let assetState = mapAssetState(sdkPreview.attributes?.assetDeliveryState?.state)
        let videoState = mapVideoState(sdkPreview.attributes?.videoDeliveryState?.state)
        return Domain.AppPreview(
            id: sdkPreview.id,
            setId: setId,
            fileName: sdkPreview.attributes?.fileName ?? "",
            fileSize: sdkPreview.attributes?.fileSize ?? 0,
            mimeType: sdkPreview.attributes?.mimeType,
            assetDeliveryState: assetState,
            videoDeliveryState: videoState,
            videoURL: sdkPreview.attributes?.videoURL,
            previewFrameTimeCode: sdkPreview.attributes?.previewFrameTimeCode
        )
    }

    private func mapAssetState(
        _ state: AppStoreConnect_Swift_SDK.AppMediaAssetState.State?
    ) -> Domain.AppPreview.AssetDeliveryState? {
        guard let state else { return nil }
        switch state {
        case .awaitingUpload: return .awaitingUpload
        case .uploadComplete: return .uploadComplete
        case .complete: return .complete
        case .failed: return .failed
        }
    }

    private func mapVideoState(
        _ state: AppStoreConnect_Swift_SDK.AppMediaVideoState.State?
    ) -> Domain.AppPreview.VideoDeliveryState? {
        guard let state else { return nil }
        switch state {
        case .awaitingUpload: return .awaitingUpload
        case .uploadComplete: return .uploadComplete
        case .processing: return .processing
        case .complete: return .complete
        case .failed: return .failed
        }
    }

    private func mimeTypeForFileName(_ fileName: String) -> String {
        switch (fileName as NSString).pathExtension.lowercased() {
        case "mp4": return "video/mp4"
        case "mov": return "video/quicktime"
        case "m4v": return "video/x-m4v"
        default: return "application/octet-stream"
        }
    }
}
