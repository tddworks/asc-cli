import Domain
import Foundation

// MARK: - HTTP abstraction for testability

public protocol HTTPPerforming: Sendable {
    func data(for request: URLRequest) async throws -> (Data, URLResponse)
}

extension URLSession: HTTPPerforming {}

// MARK: - GeminiScreenshotGenerationRepository

/// Calls the Gemini image generation API for each screen in the plan,
/// sending the screen's `imagePrompt` + the matched screenshot.
///
/// For generativelanguage.googleapis.com URLs (with or without /openai suffix),
/// uses the native generateContent API — the OpenAI-compat chat/completions endpoint
/// does not support image generation output. Other base URLs fall back to OpenAI-compat.
public struct GeminiScreenshotGenerationRepository: ScreenshotGenerationRepository {
    private let apiKey: String
    private let model: String
    private let baseURL: String
    private let httpClient: any HTTPPerforming

    public init(
        apiKey: String,
        model: String = "gemini-3.1-flash-image-preview",
        baseURL: String = "https://generativelanguage.googleapis.com/v1beta/openai",
        httpClient: (any HTTPPerforming)? = nil
    ) {
        self.apiKey = apiKey
        self.model = model
        self.baseURL = baseURL
        self.httpClient = httpClient ?? URLSession.shared
    }

    // MARK: - Protocol conformance

    public func generateImages(plan: ScreenPlan, screenshotURLs: [URL]) async throws -> [Int: Data] {
        try await withThrowingTaskGroup(of: (Int, Data).self) { group in
            for screen in plan.screens {
                let screenshotURL: URL? = screenshotURLs.first {
                    $0.lastPathComponent == screen.screenshotFile
                } ?? (screen.index < screenshotURLs.count ? screenshotURLs[screen.index] : nil)

                let prompt = screen.imagePrompt
                let index = screen.index

                group.addTask {
                    let imageData = try await self.generateSingleImage(
                        prompt: prompt,
                        screenshotURL: screenshotURL
                    )
                    return (index, imageData)
                }
            }

            var results: [Int: Data] = [:]
            for try await (index, data) in group {
                results[index] = data
            }
            return results
        }
    }

    // MARK: - Endpoint routing

    /// For any generativelanguage.googleapis.com URL, use the native generateContent API.
    /// The OpenAI-compat /chat/completions endpoint does not support image output.
    private var isGeminiNativeEndpoint: Bool {
        baseURL.contains("generativelanguage.googleapis.com")
    }

    private func generateSingleImage(prompt: String, screenshotURL: URL?) async throws -> Data {
        if isGeminiNativeEndpoint {
            return try await generateNativeGemini(prompt: prompt, screenshotURL: screenshotURL)
        } else {
            return try await generateOpenAICompat(prompt: prompt, screenshotURL: screenshotURL)
        }
    }

    // MARK: - Native Gemini generateContent API

    private func generateNativeGemini(prompt: String, screenshotURL: URL?) async throws -> Data {
        // Strip /openai suffix if present — native API doesn't use it
        var base = baseURL
        if base.hasSuffix("/") { base = String(base.dropLast()) }
        if base.hasSuffix("/openai") { base = String(base.dropLast("/openai".count)) }

        let urlString = "\(base)/models/\(model):generateContent"
        guard var components = URLComponents(string: urlString) else {
            throw APIError.unknown("Invalid Gemini URL: \(urlString)")
        }
        components.queryItems = [URLQueryItem(name: "key", value: apiKey)]
        guard let url = components.url else {
            throw APIError.unknown("Could not build Gemini URL")
        }

        // Build parts: optional screenshot inlineData + text prompt
        var parts: [[String: Any]] = []
        if let screenshotURL, let imageData = try? Data(contentsOf: screenshotURL) {
            let ext = screenshotURL.pathExtension.lowercased()
            let mimeType = (ext == "jpg" || ext == "jpeg") ? "image/jpeg" : "image/png"
            parts.append(["inlineData": ["mimeType": mimeType, "data": imageData.base64EncodedString()]])
        }
        parts.append(["text": prompt])

        let body: [String: Any] = [
            "contents": [["parts": parts]],
            "generationConfig": ["responseModalities": ["TEXT", "IMAGE"]]
        ]

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 120
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await httpClient.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.unknown("Invalid response type")
        }
        guard (200..<300).contains(httpResponse.statusCode) else {
            let body = String(data: data, encoding: .utf8) ?? ""
            throw APIError.unknown("Gemini API error \(httpResponse.statusCode): \(body)")
        }

        return try extractNativeGeminiImage(from: data)
    }

    private func extractNativeGeminiImage(from responseData: Data) throws -> Data {
        guard let json = try? JSONSerialization.jsonObject(with: responseData) as? [String: Any] else {
            throw APIError.unknown("Response is not valid JSON")
        }

        if let error = json["error"] as? [String: Any],
           let message = error["message"] as? String {
            throw APIError.unknown("Gemini error: \(message)")
        }

        // candidates[0].content.parts[].inlineData.data
        if let candidates = json["candidates"] as? [[String: Any]],
           let content = candidates.first?["content"] as? [String: Any],
           let parts = content["parts"] as? [[String: Any]] {
            for part in parts {
                if let inlineData = part["inlineData"] as? [String: Any],
                   let mimeType = inlineData["mimeType"] as? String,
                   mimeType.hasPrefix("image/"),
                   let b64 = inlineData["data"] as? String,
                   let imageData = Data(base64Encoded: b64, options: .ignoreUnknownCharacters),
                   imageData.count > 100 {
                    return imageData
                }
            }
        }

        let preview = String(data: responseData.prefix(300), encoding: .utf8) ?? ""
        throw APIError.unknown("No image data in Gemini response. Preview: \(preview)")
    }

    // MARK: - OpenAI-compatible Chat Completions (non-Gemini endpoints)

    private func generateOpenAICompat(prompt: String, screenshotURL: URL?) async throws -> Data {
        var base = baseURL.hasSuffix("/") ? String(baseURL.dropLast()) : baseURL
        let urlString = base.hasSuffix("/chat/completions") ? base : "\(base)/chat/completions"
        guard let url = URL(string: urlString) else {
            throw APIError.unknown("Invalid URL: \(urlString)")
        }

        var messageContent: [[String: Any]] = []
        if let screenshotURL, let imageData = try? Data(contentsOf: screenshotURL) {
            let ext = screenshotURL.pathExtension.lowercased()
            let mimeType = (ext == "jpg" || ext == "jpeg") ? "image/jpeg" : "image/png"
            let base64 = imageData.base64EncodedString()
            messageContent.append([
                "type": "image_url",
                "image_url": ["url": "data:\(mimeType);base64,\(base64)"]
            ])
        }
        messageContent.append(["type": "text", "text": prompt])

        let body: [String: Any] = [
            "model": model,
            "max_tokens": 4096,
            "messages": [["role": "user", "content": messageContent]]
        ]

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 120
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await httpClient.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.unknown("Invalid response type")
        }
        guard (200..<300).contains(httpResponse.statusCode) else {
            let body = String(data: data, encoding: .utf8) ?? ""
            throw APIError.unknown("API error \(httpResponse.statusCode): \(body)")
        }

        return try extractOpenAICompatImage(from: data)
    }

    private func extractOpenAICompatImage(from responseData: Data) throws -> Data {
        guard let json = try? JSONSerialization.jsonObject(with: responseData) as? [String: Any] else {
            throw APIError.unknown("Response is not valid JSON")
        }

        if let error = json["error"] as? [String: Any],
           let message = error["message"] as? String {
            throw APIError.unknown("API error: \(message)")
        }

        // choices[0].message.content as array of parts
        if let choices = json["choices"] as? [[String: Any]],
           let message = choices.first?["message"] as? [String: Any] {
            if let contentArray = message["content"] as? [[String: Any]] {
                for part in contentArray {
                    if let data = extractImageFromPart(part) { return data }
                }
            } else if let text = message["content"] as? String,
                      let data = decodeBase64Image(text) {
                return data
            }
        }

        // data[].b64_json (OpenAI Images API)
        if let dataArray = json["data"] as? [[String: Any]] {
            for item in dataArray {
                if let b64 = item["b64_json"] as? String,
                   let data = Data(base64Encoded: b64, options: .ignoreUnknownCharacters),
                   data.count > 100 { return data }
            }
        }

        let preview = String(data: responseData.prefix(200), encoding: .utf8) ?? ""
        throw APIError.unknown("No image data found in response. Preview: \(preview)")
    }

    private func extractImageFromPart(_ part: [String: Any]) -> Data? {
        let type = part["type"] as? String
        if type == "image_url",
           let imageUrl = part["image_url"] as? [String: Any],
           let urlStr = imageUrl["url"] as? String {
            return decodeBase64Image(urlStr)
        }
        if type == "image",
           let b64 = part["data"] as? String,
           let data = Data(base64Encoded: b64, options: .ignoreUnknownCharacters),
           data.count > 100 { return data }
        return nil
    }

    private func decodeBase64Image(_ text: String) -> Data? {
        if let data = Data(base64Encoded: text, options: .ignoreUnknownCharacters), data.count > 100 {
            return data
        }
        if let range = text.range(of: "base64,") {
            let b64 = String(text[range.upperBound...]).trimmingCharacters(in: .whitespacesAndNewlines)
            if let data = Data(base64Encoded: b64, options: .ignoreUnknownCharacters), data.count > 100 {
                return data
            }
        }
        return nil
    }
}

// MARK: - APIError alias

private typealias APIError = Domain.APIError
