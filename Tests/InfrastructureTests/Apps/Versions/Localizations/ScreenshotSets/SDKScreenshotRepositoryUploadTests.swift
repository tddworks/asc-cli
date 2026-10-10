@preconcurrency import AppStoreConnect_Swift_SDK
import Foundation
import Testing
@testable import Domain
@testable import Infrastructure

@Suite
struct SDKScreenshotRepositoryUploadTests {

    @Test func `should reserve the screenshot with the file's name and size and commit it with its checksum`() async throws {
        let file = try UploadFixtures.file(named: "home.png", contents: "PNGDATA")
        let stub = StubAPIClient()
        stub.willReturnPages([
            try Self.screenshot(#"{"data":{"type":"appScreenshots","id":"shot-1","attributes":{"fileName":"home.png","fileSize":7,"uploadOperations":[]}},"links":{"self":""}}"#),
            try Self.screenshot(#"{"data":{"type":"appScreenshots","id":"shot-1","attributes":{"fileName":"home.png","fileSize":7,"assetDeliveryState":{"state":"UPLOAD_COMPLETE"}}},"links":{"self":""}}"#),
        ])

        let screenshot = try await SDKScreenshotRepository(client: stub).uploadScreenshot(setId: "set-1", fileURL: file)

        #expect(screenshot == AppScreenshot(id: "shot-1", setId: "set-1", fileName: "home.png", fileSize: 7, assetState: .uploadComplete))
        #expect(stub.requests.map { "\($0.method) \($0.path) \($0.body ?? "")" } == [
            #"POST /v1/appScreenshots {"data":{"attributes":{"fileName":"home.png","fileSize":7},"relationships":{"appScreenshotSet":{"data":{"id":"set-1","type":"appScreenshotSets"}}},"type":"appScreenshots"}}"#,
            #"PATCH /v1/appScreenshots/shot-1 {"data":{"attributes":{"sourceFileChecksum":"0b75926ab9a9f9fe7d6008245c09352e","uploaded":true},"id":"shot-1","type":"appScreenshots"}}"#,
        ])
    }

    @Test func `should fail without committing the screenshot when App Store Connect's storage refuses a part`() async throws {
        let file = try UploadFixtures.file(named: "home.png", contents: "PNGDATA")
        let stub = StubAPIClient()
        stub.willReturn(try Self.screenshot(#"{"data":{"type":"appScreenshots","id":"shot-1","attributes":{"fileName":"home.png","fileSize":7,"uploadOperations":[{"method":"PUT","url":"https://upload.example.com/1","length":7,"offset":0}]}},"links":{"self":""}}"#))
        let http = SequencedStubHTTPClient()
        http.enqueue(json: "", statusCode: 500)

        await #expect(throws: (any Error).self) {
            try await SDKScreenshotRepository(client: stub, uploader: UploadOperationsExecutor(http: http)).uploadScreenshot(setId: "set-1", fileURL: file)
        }
        #expect(stub.requests.map { "\($0.method) \($0.path)" } == ["POST /v1/appScreenshots"])
    }

    @Test func `should send only the parts App Store Connect named a method for`() async throws {
        let file = try UploadFixtures.file(named: "home.png", contents: "PNGDATA")
        let stub = StubAPIClient()
        stub.willReturn(try Self.screenshot(#"{"data":{"type":"appScreenshots","id":"shot-1","attributes":{"fileName":"home.png","fileSize":7,"uploadOperations":[{"url":"https://upload.example.com/0","length":3,"offset":0},{"method":"PUT","url":"https://upload.example.com/1","length":4,"offset":3}]}},"links":{"self":""}}"#))
        let http = SequencedStubHTTPClient()
        http.enqueue(json: "", statusCode: 200)

        _ = try await SDKScreenshotRepository(client: stub, uploader: UploadOperationsExecutor(http: http)).uploadScreenshot(setId: "set-1", fileURL: file)

        #expect(http.capturedRequests.map { "\($0.httpMethod ?? "") \($0.url?.absoluteString ?? "") \(String(data: $0.httpBody ?? Data(), encoding: .utf8) ?? "")" } == [
            "PUT https://upload.example.com/1 DATA",
        ])
    }

    static func screenshot(_ json: String) throws -> AppScreenshotResponse {
        try UploadFixtures.decode(AppScreenshotResponse.self, json)
    }
}
