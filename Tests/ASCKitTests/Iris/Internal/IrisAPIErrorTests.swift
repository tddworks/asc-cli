import Foundation
import Testing
@testable import ASCKit

@Suite
struct IrisAPIErrorTests {

    @Test func `invalidResponse has descriptive message`() {
        let error = IrisAPIError.invalidResponse
        #expect(error.errorDescription == "Invalid response from iris API")
    }

    @Test func `httpError includes status code and body`() {
        let error = IrisAPIError.httpError(statusCode: 409, body: "conflict")
        #expect(error.errorDescription == "Iris API error 409: conflict")
    }

    @Test func `httpError with nil body shows no body`() {
        let error = IrisAPIError.httpError(statusCode: 500, body: nil)
        #expect(error.errorDescription == "Iris API error 500: no body")
    }

    @Test func `decodingError includes detail`() {
        let error = IrisAPIError.decodingError("missing field 'id'")
        #expect(error.errorDescription == "Failed to decode iris response: missing field 'id'")
    }
}
