@preconcurrency import AppStoreConnect_Swift_SDK
import Foundation
import Testing
@testable import Infrastructure

@Suite
struct UploadOperationsExecutorTests {

    @Test func `should send each part of the file to the URL, method and headers App Store Connect handed out`() async throws {
        let file = try Self.temporaryFile(contents: "0123456789")
        defer { try? FileManager.default.removeItem(at: file) }
        let http = SequencedStubHTTPClient()
        http.enqueue(json: "", statusCode: 200)
        http.enqueue(json: "", statusCode: 200)

        try await UploadOperationsExecutor(http: http).upload(fileURL: file, operations: [
            UploadOperation(method: "PUT", url: "https://upload.example.com/part-1", length: 4, offset: 0,
                            requestHeaders: [HTTPHeader(name: "Content-Type", value: "image/png")]),
            UploadOperation(method: "PUT", url: "https://upload.example.com/part-2", length: 6, offset: 4,
                            requestHeaders: [HTTPHeader(name: "Content-Type", value: "image/png")]),
        ])

        let sent = http.capturedRequests.map {
            "\($0.httpMethod ?? "") \($0.url?.absoluteString ?? "") \($0.value(forHTTPHeaderField: "Content-Type") ?? "") \(String(data: $0.httpBody ?? Data(), encoding: .utf8) ?? "")"
        }
        #expect(sent == [
            "PUT https://upload.example.com/part-1 image/png 0123",
            "PUT https://upload.example.com/part-2 image/png 456789",
        ])
    }

    @Test func `should fail the upload when App Store Connect's storage refuses a part`() async throws {
        let file = try Self.temporaryFile(contents: "0123")
        defer { try? FileManager.default.removeItem(at: file) }
        let http = SequencedStubHTTPClient()
        http.enqueue(json: "", statusCode: 500)

        await #expect(throws: (any Error).self) {
            try await UploadOperationsExecutor(http: http).upload(fileURL: file, operations: [
                UploadOperation(method: "PUT", url: "https://upload.example.com/part-1", length: 4, offset: 0),
            ])
        }
    }

    static func temporaryFile(contents: String) throws -> URL {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("upload-\(UUID().uuidString).png")
        try Data(contents.utf8).write(to: url)
        return url
    }
}
