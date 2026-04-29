import Foundation
import Testing
@testable import ASCCommand

@Suite
struct MultipartFormDataTests {

    // MARK: - boundary extraction

    @Test func `multipartBoundary extracts boundary from header`() {
        #expect(multipartBoundary(from: "multipart/form-data; boundary=----WebKitFormBoundary123") == "----WebKitFormBoundary123")
    }

    @Test func `multipartBoundary tolerates leading whitespace and casing`() {
        #expect(multipartBoundary(from: "Multipart/Form-Data;  boundary=abc") == "abc")
    }

    @Test func `multipartBoundary strips quotes around the boundary value`() {
        #expect(multipartBoundary(from: "multipart/form-data; boundary=\"my-boundary\"") == "my-boundary")
    }

    @Test func `multipartBoundary returns nil when content type is not multipart`() {
        #expect(multipartBoundary(from: "image/png") == nil)
        #expect(multipartBoundary(from: nil) == nil)
    }

    // MARK: - file part extraction

    @Test func `extractMultipartFilePart returns the bytes between headers and the next boundary`() {
        let body = Self.makeBody(boundary: "BOUND", fileBytes: Data([0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]))
        let part = extractMultipartFilePart(body: body, boundary: "BOUND")
        #expect(part?.bytes == Data([0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]))
    }

    @Test func `extractMultipartFilePart returns the inner Content-Type and filename`() {
        let body = Self.makeBody(boundary: "BOUND", fileBytes: Data([0xFF]))
        let part = extractMultipartFilePart(body: body, boundary: "BOUND")
        #expect(part?.contentType == "image/png")
        #expect(part?.filename == "IMG_7937.PNG")
    }

    @Test func `extractMultipartFilePart preserves binary bytes including embedded CRLF`() {
        let bytes = Data([0x00, 0x0D, 0x0A, 0xFF, 0x0D, 0x0A, 0xCC])  // a chunk that contains CRLF
        let body = Self.makeBody(boundary: "BOUND", fileBytes: bytes)
        let part = extractMultipartFilePart(body: body, boundary: "BOUND")
        #expect(part?.bytes == bytes)
    }

    @Test func `extractMultipartFilePart returns nil when no file part found`() {
        let body = Data("garbage".utf8)
        #expect(extractMultipartFilePart(body: body, boundary: "BOUND") == nil)
    }

    // MARK: - Helpers

    private static func makeBody(boundary: String, fileBytes: Data) -> Data {
        var data = Data()
        data.append(Data("--\(boundary)\r\n".utf8))
        data.append(Data("Content-Disposition: form-data; name=\"file\"; filename=\"IMG_7937.PNG\"\r\n".utf8))
        data.append(Data("Content-Type: image/png\r\n\r\n".utf8))
        data.append(fileBytes)
        data.append(Data("\r\n--\(boundary)--\r\n".utf8))
        return data
    }
}
