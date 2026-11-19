import Foundation
import Mockable

@Mockable
public protocol BuildUploads: Sendable {
    func uploadBuild(appId: String, version: String, buildNumber: String, platform: BuildUploadPlatform, fileURL: URL) async throws -> BuildUpload
    func listBuildUploads(appId: String) async throws -> [BuildUpload]
    func getBuildUpload(id: String) async throws -> BuildUpload
    func deleteBuildUpload(id: String) async throws
}
