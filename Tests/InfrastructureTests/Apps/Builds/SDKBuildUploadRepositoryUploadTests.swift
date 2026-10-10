@preconcurrency import AppStoreConnect_Swift_SDK
import Foundation
import Testing
@testable import Domain
@testable import Infrastructure

@Suite
struct SDKBuildUploadRepositoryUploadTests {

    @Test func `should open an upload, reserve the ipa by name and size, commit it and show the upload's state`() async throws {
        let file = try UploadFixtures.file(named: "MyApp.ipa", contents: "IPADATA")
        let stub = StubAPIClient()
        stub.willReturnPages([
            try Self.upload(#"{"data":{"type":"buildUploads","id":"up-1","attributes":{"cfBundleShortVersionString":"1.2.0","cfBundleVersion":"42","platform":"IOS","state":{"state":"AWAITING_UPLOAD"}}},"links":{"self":""}}"#),
            try Self.upload(#"{"data":{"type":"buildUploads","id":"up-1","attributes":{"cfBundleShortVersionString":"1.2.0","cfBundleVersion":"42","platform":"IOS","state":{"state":"PROCESSING"}}},"links":{"self":""}}"#),
        ])
        stub.willReturnPages([
            try Self.file(#"{"data":{"type":"buildUploadFiles","id":"file-1","attributes":{"fileName":"MyApp.ipa","fileSize":7,"uploadOperations":[]}},"links":{"self":""}}"#),
            try Self.file(#"{"data":{"type":"buildUploadFiles","id":"file-1","attributes":{"fileName":"MyApp.ipa","fileSize":7}},"links":{"self":""}}"#),
        ])

        let upload = try await SDKBuildUploadRepository(client: stub).uploadBuild(
            appId: "app-1", version: "1.2.0", buildNumber: "42", platform: .iOS, fileURL: file
        )

        #expect(upload == BuildUpload(id: "up-1", appId: "app-1", version: "1.2.0", buildNumber: "42", platform: .iOS, state: .processing))
        #expect(stub.requests.map { "\($0.method) \($0.path) \($0.body ?? "")" } == [
            #"POST /v1/buildUploads {"data":{"attributes":{"cfBundleShortVersionString":"1.2.0","cfBundleVersion":"42","platform":"IOS"},"relationships":{"app":{"data":{"id":"app-1","type":"apps"}}},"type":"buildUploads"}}"#,
            #"POST /v1/buildUploadFiles {"data":{"attributes":{"assetType":"ASSET","fileName":"MyApp.ipa","fileSize":7,"uti":"com.apple.ipa"},"relationships":{"buildUpload":{"data":{"id":"up-1","type":"buildUploads"}}},"type":"buildUploadFiles"}}"#,
            #"PATCH /v1/buildUploadFiles/file-1 {"data":{"attributes":{"uploaded":true},"id":"file-1","type":"buildUploadFiles"}}"#,
            #"GET /v1/buildUploads/up-1 "#,
        ])
    }

    @Test func `should fail without committing the build when App Store Connect's storage refuses a part`() async throws {
        let file = try UploadFixtures.file(named: "MyApp.ipa", contents: "IPADATA")
        let stub = StubAPIClient()
        stub.willReturn(try Self.upload(#"{"data":{"type":"buildUploads","id":"up-1","attributes":{"state":{"state":"AWAITING_UPLOAD"}}},"links":{"self":""}}"#))
        stub.willReturn(try Self.file(#"{"data":{"type":"buildUploadFiles","id":"file-1","attributes":{"fileName":"MyApp.ipa","fileSize":7,"uploadOperations":[{"method":"PUT","url":"https://upload.example.com/1","length":7,"offset":0}]}},"links":{"self":""}}"#))
        let http = SequencedStubHTTPClient()
        http.enqueue(json: "", statusCode: 500)

        await #expect(throws: (any Error).self) {
            try await SDKBuildUploadRepository(client: stub, uploader: UploadOperationsExecutor(http: http)).uploadBuild(
                appId: "app-1", version: "1.2.0", buildNumber: "42", platform: .iOS, fileURL: file
            )
        }
        #expect(stub.requests.map { "\($0.method) \($0.path)" } == ["POST /v1/buildUploads", "POST /v1/buildUploadFiles"])
    }

    @Test func `should send only the parts App Store Connect named a method for`() async throws {
        let file = try UploadFixtures.file(named: "MyApp.ipa", contents: "IPADATA")
        let stub = StubAPIClient()
        stub.willReturn(try Self.upload(#"{"data":{"type":"buildUploads","id":"up-1","attributes":{"state":{"state":"AWAITING_UPLOAD"}}},"links":{"self":""}}"#))
        stub.willReturn(try Self.file(#"{"data":{"type":"buildUploadFiles","id":"file-1","attributes":{"fileName":"MyApp.ipa","fileSize":7,"uploadOperations":[{"url":"https://upload.example.com/0","length":3,"offset":0},{"method":"PUT","url":"https://upload.example.com/1","length":4,"offset":3}]}},"links":{"self":""}}"#))
        let http = SequencedStubHTTPClient()
        http.enqueue(json: "", statusCode: 200)

        _ = try await SDKBuildUploadRepository(client: stub, uploader: UploadOperationsExecutor(http: http)).uploadBuild(
            appId: "app-1", version: "1.2.0", buildNumber: "42", platform: .iOS, fileURL: file
        )

        #expect(http.capturedRequests.map { "\($0.httpMethod ?? "") \($0.url?.absoluteString ?? "") \(String(data: $0.httpBody ?? Data(), encoding: .utf8) ?? "")" } == [
            "PUT https://upload.example.com/1 DATA",
        ])
    }

    static func upload(_ json: String) throws -> BuildUploadResponse {
        try UploadFixtures.decode(BuildUploadResponse.self, json)
    }

    static func file(_ json: String) throws -> BuildUploadFileResponse {
        try UploadFixtures.decode(BuildUploadFileResponse.self, json)
    }
}
