import Foundation
import Testing
@testable import ASCKit

@Suite
struct IrisRequestTests {
    @Test func `should ask iris for JSON:API as the web UI does, with the session cookies`() {
        let request = IrisRequest.get(path: "apps", queryItems: [URLQueryItem(name: "limit", value: "1")], cookies: "myacinfo=abc")

        #expect(request.url?.absoluteString == "https://appstoreconnect.apple.com/iris/v1/apps?limit=1")
        #expect(request.httpMethod == "GET")
        #expect(request.value(forHTTPHeaderField: "accept") == "application/vnd.api+json")
        #expect(request.value(forHTTPHeaderField: "content-type") == "application/vnd.api+json")
        #expect(request.value(forHTTPHeaderField: "cookie") == "myacinfo=abc")
        #expect(request.value(forHTTPHeaderField: "x-csrf-itc") == "[asc-ui]")
        #expect(request.value(forHTTPHeaderField: "user-agent")?.hasPrefix("Mozilla/5.0 (Macintosh") == true)
    }

    @Test func `should leave the query off when there are no query items`() {
        let request = IrisRequest.get(path: "apps", queryItems: [], cookies: "c")

        #expect(request.url?.absoluteString == "https://appstoreconnect.apple.com/iris/v1/apps")
    }

    @Test func `should send the body when posting to iris`() {
        let request = IrisRequest.post(path: "appBundles", body: Data("{}".utf8), cookies: "c")

        #expect(request.url?.absoluteString == "https://appstoreconnect.apple.com/iris/v1/appBundles")
        #expect(request.httpMethod == "POST")
        #expect(request.httpBody == Data("{}".utf8))
        #expect(request.value(forHTTPHeaderField: "x-csrf-itc") == "[asc-ui]")
    }

    @Test func `should delete at the iris path`() {
        let request = IrisRequest.delete(path: "inAppPurchaseSubmissions/s1", cookies: "c")

        #expect(request.url?.absoluteString == "https://appstoreconnect.apple.com/iris/v1/inAppPurchaseSubmissions/s1")
        #expect(request.httpMethod == "DELETE")
    }

    @Test func `should send the body when patching iris`() {
        let request = IrisRequest.patch(path: "appDataUsagesPublishState/1234567890", body: Data("{}".utf8), cookies: "c")

        #expect(request.url?.absoluteString == "https://appstoreconnect.apple.com/iris/v1/appDataUsagesPublishState/1234567890")
        #expect(request.httpMethod == "PATCH")
        #expect(request.httpBody == Data("{}".utf8))
        #expect(request.value(forHTTPHeaderField: "x-csrf-itc") == "[asc-ui]")
    }

    @Test func `should fetch a download with only the session cookies`() {
        let request = IrisRequest.download(absoluteURL: URL(string: "https://example.apple.com/a.png")!, cookies: "c")

        #expect(request.url?.absoluteString == "https://example.apple.com/a.png")
        #expect(request.httpMethod == "GET")
        #expect(request.value(forHTTPHeaderField: "cookie") == "c")
        #expect(request.value(forHTTPHeaderField: "accept") == nil)
        #expect(request.value(forHTTPHeaderField: "x-csrf-itc") == nil)
    }
}

@Suite
struct IrisComplianceRequestTests {
    @Test func `should ask the compliance service for JSON with the session cookies`() {
        let request = IrisRequest.compliance(
            method: "GET", path: "accounts/team-1/requirements",
            queryItems: [URLQueryItem(name: "entity_id", value: "1234567890")], body: nil, cookies: "myacinfo=abc"
        )

        #expect(request.url?.absoluteString
            == "https://appstoreconnect.apple.com/ppm/compliancerequirements/v1/accounts/team-1/requirements?entity_id=1234567890")
        #expect(request.httpMethod == "GET")
        #expect(request.value(forHTTPHeaderField: "accept") == "application/json")
        #expect(request.value(forHTTPHeaderField: "content-type") == "application/json")
        #expect(request.value(forHTTPHeaderField: "cookie") == "myacinfo=abc")
        #expect(request.value(forHTTPHeaderField: "x-csrf-itc") == "[asc-ui]")
        #expect(request.value(forHTTPHeaderField: "user-agent") == IrisRequest.userAgent)
        #expect(request.httpBody == nil)
    }

    @Test func `should send a declaration as the body of a save`() {
        let body = Data(#"{"fields":[]}"#.utf8)

        let request = IrisRequest.compliance(
            method: "PUT", path: "accounts/team-1/entities/1234567890/forms/form-1", queryItems: [], body: body, cookies: "c"
        )

        #expect(request.url?.absoluteString
            == "https://appstoreconnect.apple.com/ppm/compliancerequirements/v1/accounts/team-1/entities/1234567890/forms/form-1")
        #expect(request.httpMethod == "PUT")
        #expect(request.httpBody == body)
    }
}

@Suite
struct IrisResponseTests {
    private let url = URL(string: "https://appstoreconnect.apple.com/iris/v1/apps")!

    @Test func `should answer the body when iris accepts the request`() throws {
        let response = HTTPURLResponse(url: url, statusCode: 201, httpVersion: nil, headerFields: nil)!

        let (data, http) = try IrisResponse.accepted(data: Data("ok".utf8), response: response)

        #expect(data == Data("ok".utf8))
        #expect(http.statusCode == 201)
    }

    @Test func `should fail with the status and body when iris refuses the request`() {
        let response = HTTPURLResponse(url: url, statusCode: 403, httpVersion: nil, headerFields: nil)!

        do {
            _ = try IrisResponse.accepted(data: Data("forbidden".utf8), response: response)
            Issue.record("expected iris to refuse")
        } catch IrisAPIError.httpError(let statusCode, let body) {
            #expect(statusCode == 403)
            #expect(body == "forbidden")
        } catch {
            Issue.record("unexpected error \(error)")
        }
    }

    @Test func `should fail when the reply is not an HTTP response`() {
        let response = URLResponse(url: url, mimeType: nil, expectedContentLength: 0, textEncodingName: nil)

        do {
            _ = try IrisResponse.accepted(data: Data(), response: response)
            Issue.record("expected an invalid response")
        } catch IrisAPIError.invalidResponse {
        } catch {
            Issue.record("unexpected error \(error)")
        }
    }
}
