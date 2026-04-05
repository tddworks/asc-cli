import ArgumentParser
import Domain
import Foundation
import Infrastructure

struct AppShotsGenerate: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "generate",
        abstract: "Enhance App Store screenshots using Gemini AI"
    )

    @OptionGroup var globals: GlobalOptions

    @Option(name: .long, help: "Screenshot file to enhance")
    var file: String

    @Option(name: .long, help: "Gemini API key (falls back to GEMINI_API_KEY env var)")
    var geminiApiKey: String?

    @Option(name: .long, help: "Gemini model")
    var model: String = "gemini-3.1-flash-image-preview"

    @Option(name: .long, help: "Output directory")
    var outputDir: String = ".asc/app-shots/output"

    @Option(name: .long, help: "Style reference image — Gemini replicates its visual style")
    var styleReference: String?

    @Option(name: .long, help: "Named device type — resizes output to exact App Store dimensions. E.g.: APP_IPHONE_67 (1290×2796)")
    var deviceType: AppShotsDisplayType?

    @Option(name: .long, help: "Custom enhancement prompt")
    var prompt: String?

    func run() async throws {
        let configStorage = FileAppShotsConfigStorage()
        let apiKey = try resolveGeminiApiKey(geminiApiKey, configStorage: configStorage)
        print(try await execute(apiKey: apiKey))
    }

    func execute(apiKey: String) async throws -> String {
        // Read input
        let fileURL = URL(fileURLWithPath: file)
        guard let imageData = FileManager.default.contents(atPath: fileURL.path) else {
            throw ValidationError("File not found: \(file)")
        }

        // Read style reference
        let styleRefData: Data? = try {
            guard let path = styleReference, !path.isEmpty else { return nil }
            guard let data = FileManager.default.contents(atPath: path) else {
                throw ValidationError("Style reference not found: \(path)")
            }
            return data
        }()

        // Build prompt
        let enhancePrompt = buildPrompt(hasStyleRef: styleRefData != nil)

        // Call Gemini directly
        let resultData = try await callGemini(
            apiKey: apiKey,
            prompt: enhancePrompt,
            imageData: imageData,
            styleRefData: styleRefData
        )

        // Resize if device type specified
        let finalData: Data
        if let deviceType {
            let dims = deviceType.dimensions
            finalData = resizeImageData(resultData, toWidth: dims.width, height: dims.height)
        } else {
            finalData = resultData
        }

        // Write output
        let outputDirURL = URL(fileURLWithPath: outputDir)
        try FileManager.default.createDirectory(at: outputDirURL, withIntermediateDirectories: true)
        let outputPath = outputDirURL.appendingPathComponent("screen-0.png")
        try finalData.write(to: outputPath)

        return formatOutput(path: outputPath.path)
    }

    // MARK: - Gemini

    private func callGemini(
        apiKey: String,
        prompt: String,
        imageData: Data,
        styleRefData: Data?
    ) async throws -> Data {
        let base = "https://generativelanguage.googleapis.com/v1beta"
        let url = URL(string: "\(base)/models/\(model):generateContent?key=\(apiKey)")!

        // Build parts: [style ref image?] [screenshot image] [prompt text]
        var parts: [[String: Any]] = []

        if let refData = styleRefData {
            parts.append([
                "inlineData": [
                    "mimeType": "image/png",
                    "data": refData.base64EncodedString()
                ]
            ])
        }

        parts.append([
            "inlineData": [
                "mimeType": "image/png",
                "data": imageData.base64EncodedString()
            ]
        ])

        parts.append(["text": prompt])

        let body: [String: Any] = [
            "contents": [["parts": parts]],
            "generationConfig": [
                "responseModalities": ["TEXT", "IMAGE"],
                "temperature": 1.0,
            ]
        ]

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw ValidationError("Invalid response from Gemini")
        }
        guard httpResponse.statusCode == 200 else {
            let errorText = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw ValidationError("Gemini API error \(httpResponse.statusCode): \(errorText)")
        }

        // Parse response — extract base64 image from candidates
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let candidates = json["candidates"] as? [[String: Any]],
              let content = candidates.first?["content"] as? [String: Any],
              let responseParts = content["parts"] as? [[String: Any]] else {
            throw ValidationError("Failed to parse Gemini response")
        }

        for part in responseParts {
            if let inlineData = part["inlineData"] as? [String: Any],
               let b64 = inlineData["data"] as? String,
               let imageData = Data(base64Encoded: b64) {
                return imageData
            }
        }

        throw ValidationError("No image in Gemini response")
    }

    // MARK: - Prompt

    private func buildPrompt(hasStyleRef: Bool) -> String {
        if let custom = prompt, !custom.isEmpty {
            return custom
        }

        if hasStyleRef {
            return """
            Enhance this App Store screenshot to match the visual style of the reference image.

            FIRST image = style reference. Match its device frame, text treatment, background, polish level.
            SECOND image = screenshot to enhance. Keep its layout, text, and content exactly.

            Requirements:
            - Photorealistic iPhone mockup with reflections and shadows
            - Match the reference's background, text rendering, and aesthetic
            - Keep all existing text and layout unchanged
            - Professional App Store quality
            - No watermarks, no extra text
            """
        }

        return """
        You are a professional App Store screenshot designer. Analyze this image and enhance it into a high-converting marketing screenshot.

        FIRST — analyze what's on screen:
        - What app is this? What does it do?
        - What's the most compelling feature visible?
        - What headline text exists (if any)?
        - What's the dominant color scheme?

        THEN — enhance following these rules:

        KEEP EXACTLY:
        - The app screenshot content shown on the device
        - The overall layout (text position relative to device)
        - Any existing headline/subtitle text wording

        ENHANCE:
        - Device frame: replace with a photorealistic iPhone 15 Pro mockup — sleek, with accurate proportions, reflections, and subtle shadows. The phone should look like a real physical device.
        - Breakout element: find the most compelling UI panel on the app screen and make it "break out" from the device frame — scale it up significantly so it extends beyond BOTH left and right edges of the phone, overlapping the bezel. Add a soft drop shadow beneath it to create depth. The panel must stay at the same vertical position as on screen — do NOT rotate it.
        - Headline text: if existing text doesn't match the app, replace it with a strong 2-4 word ACTION VERB headline (e.g. "TRACK WEATHER", "MANAGE YOUR APPS") in large bold white uppercase. Add a subtitle in smaller italic text below.
        - Background: use a clean gradient that complements the app's color scheme. Dark apps get dark backgrounds (deep navy/black). Light apps get light backgrounds. No glows, noise, or radial patterns.
        - Supporting elements: add 1-2 small contextual elements (badges, stats, icons) floating near the device that reinforce the app's value. These should feel natural, not forced.
        - Text must be crisp, bold, and readable at thumbnail size

        The result should look like it was designed by a professional App Store screenshot agency — polished, high-converting, visually striking. No watermarks, no extra text, no app store UI chrome.
        """
    }

    // MARK: - Output

    private func formatOutput(path: String) -> String {
        switch globals.outputFormat {
        case .table:
            return "| File |\n|------|\n| \(path) |"
        case .markdown:
            return "- Generated: `\(path)`"
        default:
            if globals.pretty {
                return "{\n  \"generated\" : \"\(path)\"\n}"
            } else {
                return "{\"generated\":\"\(path)\"}"
            }
        }
    }
}
