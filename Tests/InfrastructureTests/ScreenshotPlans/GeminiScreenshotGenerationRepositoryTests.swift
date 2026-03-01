import Foundation
import Testing
@testable import Infrastructure
@testable import Domain

// MARK: - Stub HTTP client

final class StubHTTPClient: HTTPPerforming, @unchecked Sendable {
    var response: (Data, URLResponse)?
    var error: Error?
    private(set) var lastRequest: URLRequest?

    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        lastRequest = request
        if let error { throw error }
        return response!
    }
}

private func makeHTTPResponse(statusCode: Int = 200, url: String = "https://generativelanguage.googleapis.com") -> HTTPURLResponse {
    HTTPURLResponse(url: URL(string: url)!, statusCode: statusCode, httpVersion: nil, headerFields: nil)!
}

/// Minimal PNG bytes (valid magic + padding)
private let fakePNGData: Data = {
    var bytes: [UInt8] = [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]
    bytes += [UInt8](repeating: 0x00, count: 200)
    return Data(bytes)
}()

/// Native Gemini generateContent response with image inlineData
private func makeNativeGeminiImageResponse(imageData: Data = fakePNGData) -> Data {
    let b64 = imageData.base64EncodedString()
    let body = """
    {
      "candidates": [
        {
          "content": {
            "parts": [
              {
                "inlineData": {
                  "mimeType": "image/png",
                  "data": "\(b64)"
                }
              }
            ]
          }
        }
      ]
    }
    """
    return body.data(using: .utf8)!
}

/// OpenAI-compat response with image_url content part
private func makeOpenAICompatImageResponse(imageData: Data = fakePNGData) -> Data {
    let b64 = imageData.base64EncodedString()
    let body = """
    {
      "choices": [
        {
          "message": {
            "content": [
              {
                "type": "image_url",
                "image_url": { "url": "data:image/png;base64,\(b64)" }
              }
            ]
          }
        }
      ]
    }
    """
    return body.data(using: .utf8)!
}

private func makeSingleScreenPlan(imagePrompt: String = "App screenshot on dark navy background") -> ScreenPlan {
    ScreenPlan(
        appId: "app-123",
        appName: "TestApp",
        tagline: "Great app",
        tone: .professional,
        colors: ScreenColors(primary: "#000000", accent: "#FF0000", text: "#FFFFFF", subtext: "#CCCCCC"),
        screens: [
            ScreenConfig(
                index: 0,
                screenshotFile: "screen1.png",
                heading: "Work Smarter",
                subheading: "Organize your tasks",
                layoutMode: .center,
                visualDirection: "Main dashboard",
                imagePrompt: imagePrompt
            )
        ]
    )
}

// MARK: - Tests

@Suite
struct GeminiScreenshotGenerationRepositoryTests {

    // MARK: Native Gemini API (generativelanguage.googleapis.com)

    @Test func `generateImages uses native generateContent API for Gemini URLs`() async throws {
        let stub = StubHTTPClient()
        stub.response = (makeNativeGeminiImageResponse(), makeHTTPResponse())

        let repo = GeminiScreenshotGenerationRepository(
            apiKey: "test-key",
            baseURL: "https://generativelanguage.googleapis.com/v1beta/openai",
            httpClient: stub
        )
        _ = try await repo.generateImages(plan: makeSingleScreenPlan(), screenshotURLs: [], styleReferenceURL: nil)

        // Must use native endpoint, not /chat/completions
        let url = stub.lastRequest?.url?.absoluteString ?? ""
        #expect(url.contains("/models/"))
        #expect(url.contains(":generateContent"))
        #expect(url.contains("key=test-key"))
        #expect(!url.contains("chat/completions"))
    }

    @Test func `generateImages strips openai suffix when building native URL`() async throws {
        let stub = StubHTTPClient()
        stub.response = (makeNativeGeminiImageResponse(), makeHTTPResponse())

        let repo = GeminiScreenshotGenerationRepository(
            apiKey: "my-key",
            model: "gemini-3.1-flash-image-preview",
            baseURL: "https://generativelanguage.googleapis.com/v1beta/openai",
            httpClient: stub
        )
        _ = try await repo.generateImages(plan: makeSingleScreenPlan(), screenshotURLs: [], styleReferenceURL: nil)

        let url = stub.lastRequest?.url?.absoluteString ?? ""
        #expect(url == "https://generativelanguage.googleapis.com/v1beta/models/gemini-3.1-flash-image-preview:generateContent?key=my-key")
    }

    @Test func `generateImages returns PNG data from native Gemini inlineData`() async throws {
        let stub = StubHTTPClient()
        stub.response = (makeNativeGeminiImageResponse(), makeHTTPResponse())

        let repo = GeminiScreenshotGenerationRepository(apiKey: "test-key", httpClient: stub)
        let results = try await repo.generateImages(plan: makeSingleScreenPlan(), screenshotURLs: [], styleReferenceURL: nil)

        #expect(results.count == 1)
        #expect(results[0] != nil)
        #expect(results[0]!.count > 100)
    }

    @Test func `generateImages native API sends imagePrompt as text part`() async throws {
        let stub = StubHTTPClient()
        stub.response = (makeNativeGeminiImageResponse(), makeHTTPResponse())

        let repo = GeminiScreenshotGenerationRepository(apiKey: "key", httpClient: stub)
        _ = try await repo.generateImages(
            plan: makeSingleScreenPlan(imagePrompt: "Dark navy with glowing accents"),
            screenshotURLs: [],
            styleReferenceURL: nil
        )

        let bodyData = stub.lastRequest?.httpBody ?? Data()
        let bodyString = String(data: bodyData, encoding: .utf8) ?? ""
        #expect(bodyString.contains("Dark navy with glowing accents"))
        #expect(bodyString.contains("responseModalities"))
        #expect(bodyString.contains("IMAGE"))
    }

    @Test func `generateImages native API uses model in URL`() async throws {
        let stub = StubHTTPClient()
        stub.response = (makeNativeGeminiImageResponse(), makeHTTPResponse())

        let repo = GeminiScreenshotGenerationRepository(
            apiKey: "key",
            model: "gemini-3.1-flash-image-preview",
            httpClient: stub
        )
        _ = try await repo.generateImages(plan: makeSingleScreenPlan(), screenshotURLs: [], styleReferenceURL: nil)

        let url = stub.lastRequest?.url?.absoluteString ?? ""
        #expect(url.contains("gemini-3.1-flash-image-preview"))
    }

    @Test func `generateImages throws on HTTP error`() async throws {
        let stub = StubHTTPClient()
        stub.response = ("Unauthorized".data(using: .utf8)!, makeHTTPResponse(statusCode: 401))

        let repo = GeminiScreenshotGenerationRepository(apiKey: "bad-key", httpClient: stub)
        do {
            _ = try await repo.generateImages(plan: makeSingleScreenPlan(), screenshotURLs: [], styleReferenceURL: nil)
            Issue.record("Expected error to be thrown")
        } catch let error as Domain.APIError {
            if case .unknown(let msg) = error {
                #expect(msg.contains("401"))
            } else {
                Issue.record("Expected APIError.unknown, got \(error)")
            }
        }
    }

    @Test func `generateImages throws when no image in native response`() async throws {
        let stub = StubHTTPClient()
        let emptyResponse = Data(#"{"candidates":[{"content":{"parts":[{"text":"no image"}]}}]}"#.utf8)
        stub.response = (emptyResponse, makeHTTPResponse())

        let repo = GeminiScreenshotGenerationRepository(apiKey: "key", httpClient: stub)
        do {
            _ = try await repo.generateImages(plan: makeSingleScreenPlan(), screenshotURLs: [], styleReferenceURL: nil)
            Issue.record("Expected error to be thrown")
        } catch let error as Domain.APIError {
            if case .unknown(let msg) = error {
                #expect(msg.contains("No image data"))
            } else {
                Issue.record("Expected APIError.unknown, got \(error)")
            }
        }
    }

    @Test func `generateImages returns empty dict for plan with no screens`() async throws {
        let stub = StubHTTPClient()
        let emptyPlan = ScreenPlan(
            appId: "app-1", appName: "App", tagline: "t", tone: .minimal,
            colors: ScreenColors(primary: "#000", accent: "#fff", text: "#fff", subtext: "#ccc"),
            screens: []
        )

        let repo = GeminiScreenshotGenerationRepository(apiKey: "key", httpClient: stub)
        let results = try await repo.generateImages(plan: emptyPlan, screenshotURLs: [], styleReferenceURL: nil)

        #expect(results.isEmpty)
    }

    // MARK: OpenAI-compat path (non-Gemini endpoints)

    @Test func `generateImages uses OpenAI compat endpoint for non-Gemini base URLs`() async throws {
        let stub = StubHTTPClient()
        stub.response = (makeOpenAICompatImageResponse(), makeHTTPResponse(url: "https://api.openai.com"))

        let repo = GeminiScreenshotGenerationRepository(
            apiKey: "sk-test",
            baseURL: "https://api.openai.com/v1",
            httpClient: stub
        )
        _ = try await repo.generateImages(plan: makeSingleScreenPlan(), screenshotURLs: [], styleReferenceURL: nil)

        let url = stub.lastRequest?.url?.absoluteString ?? ""
        #expect(url.contains("chat/completions"))
        #expect(stub.lastRequest?.value(forHTTPHeaderField: "Authorization") == "Bearer sk-test")
    }

    @Test func `generateImages includes style reference image and instruction before screenshot`() async throws {
        let stub = StubHTTPClient()
        stub.response = (makeNativeGeminiImageResponse(), makeHTTPResponse())

        // Write a real temp PNG as the style reference
        let refDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("gemini-ref-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: refDir, withIntermediateDirectories: true)
        let refFile = refDir.appendingPathComponent("style.png")
        try fakePNGData.write(to: refFile)
        defer { try? FileManager.default.removeItem(at: refDir) }

        let repo = GeminiScreenshotGenerationRepository(apiKey: "key", httpClient: stub)
        _ = try await repo.generateImages(
            plan: makeSingleScreenPlan(),
            screenshotURLs: [],
            styleReferenceURL: refFile
        )

        // Parse actual body and round-trip both through JSONSerialization with sortedKeys
        // so the full structure can be compared as a canonical string in one assertion.
        let bodyData = try #require(stub.lastRequest?.httpBody)
        let actualJSON = try #require(JSONSerialization.jsonObject(with: bodyData) as? [String: Any])

        // Expected: [ref image inlineData, style-guide text, imagePrompt text]
        // screenshotURLs is empty so no screenshot inlineData part.
        // buildAppContext produces: "App context: App: <appName>. <tagline>"
        let expectedJSON: [String: Any] = [
            "contents": [[
                "parts": [
                    ["inlineData": ["mimeType": "image/png", "data": fakePNGData.base64EncodedString()]],
                    ["text": "Use the above image as a STYLE GUIDE only — match its colors, typography, background gradients, and visual composition. Do NOT copy its content."],
                    ["text": "App context: App: TestApp. Great app\n\nApp screenshot on dark navy background"]
                ]
            ]],
            "generationConfig": ["responseModalities": ["TEXT", "IMAGE"]]
        ]

        let opts: JSONSerialization.WritingOptions = [.sortedKeys, .prettyPrinted]
        let actual   = try #require(String(data: JSONSerialization.data(withJSONObject: actualJSON,   options: opts), encoding: .utf8))
        let expected = try #require(String(data: JSONSerialization.data(withJSONObject: expectedJSON, options: opts), encoding: .utf8))
        #expect(actual == expected)
    }
}
