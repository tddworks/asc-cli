import ArgumentParser
import Domain
import Foundation
import Hummingbird
import HummingbirdWebSocket
import Infrastructure

/// `POST /api/v1/versions/:versionId/screenshots/import?to-library=true` — the body is the
/// export ZIP. Query params match the CLI flags (`existing`, `dry-run`, repeated
/// `placement-group`). Synchronous: the response arrives once every group is placed.
struct ScreenshotImportController: Sendable {
    let versionRepo: any VersionRepository
    let localizationRepo: any VersionLocalizationRepository
    let libraryRepo: any AssetLibraryRepository
    let imageRepo: any LibraryImageRepository
    let placementRepo: any AssetPlacementRepository

    /// Export ZIPs hold every locale's screenshots.
    static let maxZipBytes = 500 * 1024 * 1024

    func addRoutes(to group: RouterGroup<BasicWebSocketRequestContext>) {
        group.post("/versions/:versionId/screenshots/import") { request, context -> Response in
            guard let versionId = context.parameters.get("versionId") else { return jsonError("Missing versionId") }
            let query = request.uri.queryParameters.map { (String($0.key), String($0.value)) }
            do {
                // Check the options before reading the body; `--from` is filled in once it's spooled.
                _ = try Self.command(versionId: versionId, zipPath: "-", query: query)
            } catch {
                return jsonError(ScreenshotsImport.message(for: error))
            }
            do {
                return try await uploadReviewBody(request: request, fileExtension: "zip", maxBytes: Self.maxZipBytes) { zipURL in
                    let cmd = try Self.command(versionId: versionId, zipPath: zipURL.path, query: query)
                    let (manifest, imageURLs, tempDir) = try ScreenshotsImport.unzipAndParse(zipURL: zipURL)
                    defer { try? FileManager.default.removeItem(at: tempDir) }
                    let report = try await cmd.executeToLibrary(
                        manifest: manifest,
                        files: try ScreenshotImportFiles.read(manifest: manifest, imageURLs: imageURLs),
                        versionRepo: self.versionRepo, localizationRepo: self.localizationRepo,
                        libraryRepo: self.libraryRepo, imageRepo: self.imageRepo, placementRepo: self.placementRepo,
                        affordanceMode: .rest
                    )
                    return restResponse(report.output)
                }
            } catch let error as ValidationError {
                return jsonError(error.message)
            } catch {
                return jsonError("screenshots import failed: \(error)", status: .internalServerError)
            }
        }
    }

    /// The CLI command the query params describe — the same flags, so CLI and REST can't drift.
    static func command(versionId: String, zipPath: String, query: [(String, String)]) throws -> ScreenshotsImport {
        guard query.contains(where: { $0.0 == "to-library" && $0.1 == "true" }) else {
            throw ValidationError("Only imports into the asset library are served over REST — add ?to-library=true")
        }
        var args = ["--version-id", versionId, "--from", zipPath, "--to-library", "--pretty"]
        for (key, value) in query {
            switch key {
            case "existing", "placement-group": args += ["--\(key)", value]
            case "dry-run" where value == "true": args.append("--dry-run")
            default: break
            }
        }
        return try ScreenshotsImport.parse(args)
    }
}
