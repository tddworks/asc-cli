import ArgumentParser
import CryptoKit
import Domain
import Foundation
import ImageIO

/// Measures and hashes the screenshots an export manifest names, so the Domain planner
/// can match sizes to placement groups and upload identical files once.
enum ScreenshotImportFiles {
    static func read(manifest: ScreenshotManifest, imageURLs: [String: URL]) throws -> [ScreenshotImportFile] {
        let entries = manifest.localizations.keys.sorted().flatMap { locale in
            (manifest.localizations[locale]?.screenshots ?? []).sorted { $0.order < $1.order }
        }
        return try entries.map { entry in
            guard let url = imageURLs[entry.file], let data = try? Data(contentsOf: url) else {
                throw ValidationError("\(entry.file) is in the manifest but not in the export")
            }
            guard let source = CGImageSourceCreateWithData(data as CFData, nil),
                  let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any],
                  let width = properties[kCGImagePropertyPixelWidth] as? Int,
                  let height = properties[kCGImagePropertyPixelHeight] as? Int
            else {
                throw ValidationError("\(entry.file) isn't an image asc can read")
            }
            let hash = SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
            return ScreenshotImportFile(file: entry.file, url: url, contentHash: hash, width: width, height: height)
        }
    }
}
