@preconcurrency import AppStoreConnect_Swift_SDK
import Domain
import Foundation

public struct SDKBuildUploadRepository: BuildUploadRepository, @unchecked Sendable {
    private let client: any APIClient
    private let uploader: UploadOperationsExecutor

    public init(client: any APIClient, uploader: UploadOperationsExecutor = UploadOperationsExecutor()) {
        self.client = client
        self.uploader = uploader
    }

    public func uploadBuild(
        appId: String,
        version: String,
        buildNumber: String,
        platform: Domain.BuildUploadPlatform,
        fileURL: URL
    ) async throws -> Domain.BuildUpload {
        guard let sdkPlatform = AppStoreConnect_Swift_SDK.Platform(rawValue: platform.rawValue) else {
            throw Domain.APIError.unknown("Unsupported platform: \(platform.rawValue)")
        }

        // Step 1: Create upload session
        let createBody = BuildUploadCreateRequest(
            data: .init(
                type: .buildUploads,
                attributes: .init(
                    cfBundleShortVersionString: version,
                    cfBundleVersion: buildNumber,
                    platform: sdkPlatform
                ),
                relationships: .init(
                    app: .init(data: .init(type: .apps, id: appId))
                )
            )
        )
        let uploadSession = try await client.request(APIEndpoint.v1.buildUploads.post(createBody))
        let uploadId = uploadSession.data.id

        // Step 2: Reserve file slot — get upload operations
        let fileName = fileURL.lastPathComponent
        let fileSize = try (FileManager.default.attributesOfItem(atPath: fileURL.path)[.size] as? NSNumber)?.int64Value ?? 0
        let uti: BuildUploadFileCreateRequest.Data.Attributes.Uti =
            fileURL.pathExtension.lowercased() == "pkg" ? .comApplePkg : .comAppleIpa

        let fileBody = BuildUploadFileCreateRequest(
            data: .init(
                type: .buildUploadFiles,
                attributes: .init(assetType: .asset, fileName: fileName, fileSize: fileSize, uti: uti),
                relationships: .init(buildUpload: .init(data: .init(type: .buildUploads, id: uploadId)))
            )
        )
        let fileResponse = try await client.request(APIEndpoint.v1.buildUploadFiles.post(fileBody))
        let fileId = fileResponse.data.id
        let uploadOps = fileResponse.data.attributes?.uploadOperations ?? []

        // Step 3: Upload chunks to presigned URLs — build files describe parts with 64-bit
        // offsets; the executor only needs method/url/range/headers.
        try await uploader.upload(fileURL: fileURL, operations: uploadOps.map {
            UploadOperation(
                method: $0.method, url: $0.url,
                length: $0.length.map(Int.init), offset: $0.offset.map(Int.init),
                requestHeaders: $0.requestHeaders
            )
        })

        // Step 4: Commit upload — checksums are optional; don't send any to avoid API rejection
        let confirmBody = BuildUploadFileUpdateRequest(
            data: .init(
                type: .buildUploadFiles,
                id: fileId,
                attributes: .init(
                    sourceFileChecksums: nil,
                    isUploaded: true
                )
            )
        )
        _ = try await client.request(APIEndpoint.v1.buildUploadFiles.id(fileId).patch(confirmBody))

        // Step 5: Return current upload state
        let finalResponse = try await client.request(APIEndpoint.v1.buildUploads.id(uploadId).get())
        return mapBuildUpload(finalResponse.data, appId: appId)
    }

    public func listBuildUploads(appId: String) async throws -> [Domain.BuildUpload] {
        let pages = try await client.requestAllPages(
            APIEndpoint.v1.apps.id(appId).buildUploads.get(parameters: .init(limit: 200)),
            nextCursor: { $0.meta?.paging.nextCursor }
        )
        return pages.flatMap(\.data).map { mapBuildUpload($0, appId: appId) }
    }

    public func getBuildUpload(id: String) async throws -> Domain.BuildUpload {
        let request = APIEndpoint.v1.buildUploads.id(id).get()
        let response = try await client.request(request)
        // appId is not available in a single-resource GET — inject empty string
        // listBuilds affordance is suppressed when appId is empty (see BuildUpload.affordances)
        return mapBuildUpload(response.data, appId: "")
    }

    public func deleteBuildUpload(id: String) async throws {
        try await client.request(APIEndpoint.v1.buildUploads.id(id).delete)
    }

    private func mapBuildUpload(
        _ sdk: AppStoreConnect_Swift_SDK.BuildUpload,
        appId: String
    ) -> Domain.BuildUpload {
        let sdkState = sdk.attributes?.state
        return Domain.BuildUpload(
            id: sdk.id,
            appId: appId,
            version: sdk.attributes?.cfBundleShortVersionString ?? "",
            buildNumber: sdk.attributes?.cfBundleVersion ?? "",
            platform: mapPlatform(sdk.attributes?.platform),
            state: mapState(sdkState?.state),
            createdDate: sdk.attributes?.createdDate,
            uploadedDate: sdk.attributes?.uploadedDate,
            errors: mapStateDetails(sdkState?.errors),
            warnings: mapStateDetails(sdkState?.warnings),
            infos: mapStateDetails(sdkState?.infos)
        )
    }

    private func mapStateDetails(_ details: [AppStoreConnect_Swift_SDK.StateDetail]?) -> [Domain.BuildUploadStateDetail] {
        (details ?? []).compactMap { detail in
            guard let code = detail.code, let desc = detail.description else { return nil }
            return Domain.BuildUploadStateDetail(code: code, description: desc)
        }
    }

    private func mapState(_ sdkState: AppStoreConnect_Swift_SDK.BuildUploadState?) -> Domain.BuildUploadState {
        guard let sdkState else { return .awaitingUpload }
        switch sdkState {
        case .awaitingUpload: return .awaitingUpload
        case .processing: return .processing
        case .failed: return .failed
        case .complete: return .complete
        }
    }

    private func mapPlatform(_ sdk: AppStoreConnect_Swift_SDK.Platform?) -> Domain.BuildUploadPlatform {
        guard let sdk else { return .iOS }
        switch sdk {
        case .macOs: return .macOS
        case .tvOs: return .tvOS
        case .visionOs: return .visionOS
        default: return .iOS
        }
    }
}

