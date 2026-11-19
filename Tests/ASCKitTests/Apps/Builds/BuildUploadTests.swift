import Foundation
import Testing
@testable import ASCKit

@Suite
struct BuildUploadTests {

    @Test func `build upload carries app id`() {
        let upload = MockRepositoryFactory.makeBuildUpload(id: "up-1", appId: "app-42")
        #expect(upload.appId == "app-42")
    }

    @Test func `complete upload affordances include checkStatus and listBuilds`() {
        let upload = MockRepositoryFactory.makeBuildUpload(id: "up-1", appId: "app-1", state: .complete)
        #expect(upload.affordances["checkStatus"] == "asc builds uploads get --upload-id up-1")
        #expect(upload.affordances["listBuilds"] == "asc builds list --app-id app-1")
    }

    @Test func `processing upload affordances omit listBuilds`() {
        let upload = MockRepositoryFactory.makeBuildUpload(id: "up-1", appId: "app-1", state: .processing)
        #expect(upload.affordances["checkStatus"] == "asc builds uploads get --upload-id up-1")
        #expect(upload.affordances["listBuilds"] == nil)
    }

    @Test func `failed upload affordances omit listBuilds`() {
        let upload = MockRepositoryFactory.makeBuildUpload(id: "up-1", appId: "app-1", state: .failed)
        #expect(upload.affordances["listBuilds"] == nil)
    }

    @Test func `state semantic booleans`() {
        #expect(BuildUploadState.complete.isComplete)
        #expect(!BuildUploadState.processing.isComplete)
        #expect(BuildUploadState.failed.hasFailed)
        #expect(!BuildUploadState.complete.hasFailed)
        #expect(BuildUploadState.processing.isPending)
        #expect(BuildUploadState.awaitingUpload.isPending)
        #expect(!BuildUploadState.complete.isPending)
        #expect(!BuildUploadState.failed.isPending)
    }

    @Test func `platform cli argument init`() {
        #expect(BuildUploadPlatform(cliArgument: "ios") == .iOS)
        #expect(BuildUploadPlatform(cliArgument: "macos") == .macOS)
        #expect(BuildUploadPlatform(cliArgument: "tvos") == .tvOS)
        #expect(BuildUploadPlatform(cliArgument: "visionos") == .visionOS)
        #expect(BuildUploadPlatform(cliArgument: "unknown") == nil)
    }

    @Test func `whats new fields are omitted from json when nil`() throws {
        let upload = BuildUpload(
            id: "up-1", appId: "app-1", version: "1.0", buildNumber: "1",
            platform: .iOS, state: .processing, createdDate: nil, uploadedDate: nil
        )
        let encoder = JSONEncoder()
        encoder.outputFormatting = .sortedKeys
        let data = try encoder.encode(upload)
        let json = String(decoding: data, as: UTF8.self)
        #expect(!json.contains("createdDate"))
        #expect(!json.contains("uploadedDate"))
    }

    @Test func `errors warnings infos are omitted from json when empty`() throws {
        let upload = BuildUpload(
            id: "up-1", appId: "app-1", version: "1.0", buildNumber: "1",
            platform: .iOS, state: .failed
        )
        let data = try JSONEncoder().encode(upload)
        let json = String(decoding: data, as: UTF8.self)
        #expect(!json.contains("errors"))
        #expect(!json.contains("warnings"))
        #expect(!json.contains("infos"))
    }

    @Test func `errors are included in json when present`() throws {
        let upload = BuildUpload(
            id: "up-1", appId: "app-1", version: "1.0", buildNumber: "1",
            platform: .iOS, state: .failed,
            errors: [BuildUploadStateDetail(code: "INVALID_BINARY", description: "Binary is invalid")]
        )
        let data = try JSONEncoder().encode(upload)
        let json = String(decoding: data, as: UTF8.self)
        #expect(json.contains("errors"))
        #expect(json.contains("INVALID_BINARY"))
        #expect(json.contains("Binary is invalid"))
        #expect(!json.contains("warnings"))
        #expect(!json.contains("infos"))
    }

    @Test func `decode round-trip preserves all fields`() throws {
        let original = BuildUpload(
            id: "up-1", appId: "app-1", version: "2.0", buildNumber: "99",
            platform: .macOS, state: .failed,
            errors: [BuildUploadStateDetail(code: "ERR", description: "Something broke")]
        )
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(BuildUpload.self, from: data)
        #expect(decoded.id == "up-1")
        #expect(decoded.appId == "app-1")
        #expect(decoded.version == "2.0")
        #expect(decoded.buildNumber == "99")
        #expect(decoded.platform == .macOS)
        #expect(decoded.state == .failed)
        #expect(decoded.errors.count == 1)
        #expect(decoded.errors[0].code == "ERR")
        #expect(decoded.warnings.isEmpty)
        #expect(decoded.infos.isEmpty)
    }
}
