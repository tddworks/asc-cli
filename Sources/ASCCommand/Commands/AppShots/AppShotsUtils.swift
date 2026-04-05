import ArgumentParser
import CoreGraphics
import Domain
import Foundation
import ImageIO

/// Resolves the Gemini API key from CLI argument, environment variable, or saved config.
func resolveGeminiApiKey(_ cliArgument: String?, configStorage: any AppShotsConfigStorage) throws -> String {
    if let key = cliArgument, !key.isEmpty { return key }
    if let key = ProcessInfo.processInfo.environment["GEMINI_API_KEY"], !key.isEmpty { return key }
    if let config = try configStorage.load(), !config.geminiApiKey.isEmpty { return config.geminiApiKey }
    throw ValidationError(
        "Gemini API key required. Use --gemini-api-key, set GEMINI_API_KEY env var, or run:\n  asc app-shots config --gemini-api-key KEY"
    )
}

/// Resizes PNG/JPEG data to the given pixel dimensions using CoreGraphics.
/// Falls back to the original data if anything fails (e.g. in unit tests with fake PNG bytes).
func resizeImageData(_ data: Data, toWidth width: Int, height: Int) -> Data {
    guard let source = CGImageSourceCreateWithData(data as CFData, nil),
          let cgImage = CGImageSourceCreateImageAtIndex(source, 0, nil),
          let context = CGContext(
            data: nil, width: width, height: height,
            bitsPerComponent: 8, bytesPerRow: 0,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
          )
    else { return data }

    context.interpolationQuality = .high
    context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))

    guard let resized = context.makeImage() else { return data }

    let mutableData = NSMutableData()
    guard let dest = CGImageDestinationCreateWithData(mutableData, "public.png" as CFString, 1, nil) else { return data }
    CGImageDestinationAddImage(dest, resized, nil)
    guard CGImageDestinationFinalize(dest) else { return data }
    return mutableData as Data
}

