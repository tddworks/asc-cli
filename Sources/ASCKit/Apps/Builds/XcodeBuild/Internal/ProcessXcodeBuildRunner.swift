import Foundation

/// Error thrown when xcodebuild fails.
public enum XcodeBuildError: Error, CustomStringConvertible {
    case archiveFailed(exitCode: Int32, stderr: String)
    case exportFailed(exitCode: Int32, stderr: String)
    case noExportedBinary(exportPath: String)

    public var description: String {
        switch self {
        case .archiveFailed(let code, let stderr):
            return "xcodebuild archive failed (exit \(code)):\n\(stderr)"
        case .exportFailed(let code, let stderr):
            return "xcodebuild -exportArchive failed (exit \(code)):\n\(stderr)"
        case .noExportedBinary(let path):
            return "No .ipa or .pkg found in export directory: \(path)"
        }
    }
}

/// Runs `xcodebuild archive` and `xcodebuild -exportArchive` as subprocesses.
public struct ProcessXcodeBuildRunner: XcodeBuildRunner {

    private let xcodebuildPath: String

    public init(xcodebuildPath: String = "/usr/bin/xcodebuild") {
        self.xcodebuildPath = xcodebuildPath
    }

    public func archive(request: ArchiveRequest) async throws -> ArchiveResult {
        var args = ["archive"]

        if let workspace = request.workspace {
            args += ["-workspace", workspace]
        } else if let project = request.project {
            args += ["-project", project]
        }

        args += ["-scheme", request.scheme]
        args += ["-archivePath", request.archivePath]
        args += ["-configuration", request.configuration]
        args += ["-destination", destination(for: request.platform)]

        let (exitCode, _, stderr) = try runProcess(arguments: args)

        guard exitCode == 0 else {
            throw XcodeBuildError.archiveFailed(exitCode: exitCode, stderr: stderr)
        }

        return ArchiveResult(
            archivePath: request.archivePath,
            scheme: request.scheme,
            platform: request.platform
        )
    }

    public func exportArchive(request: ExportRequest) async throws -> ExportResult {
        let plistPath = try writeExportOptionsPlist(request: request)

        var args = [
            "-exportArchive",
            "-archivePath", request.archivePath,
            "-exportPath", request.exportPath,
            "-exportOptionsPlist", plistPath,
        ]

        if request.signingStyle == .automatic {
            args += ["-allowProvisioningUpdates"]
        }

        let (exitCode, _, stderr) = try runProcess(arguments: args)

        // Clean up temp plist
        try? FileManager.default.removeItem(atPath: plistPath)

        guard exitCode == 0 else {
            throw XcodeBuildError.exportFailed(exitCode: exitCode, stderr: stderr)
        }

        guard let binaryPath = findExportedBinary(in: request.exportPath) else {
            throw XcodeBuildError.noExportedBinary(exportPath: request.exportPath)
        }

        return ExportResult(ipaPath: binaryPath, exportPath: request.exportPath)
    }

    // MARK: - Private

    private func runProcess(arguments: [String]) throws -> (Int32, String, String) {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: xcodebuildPath)
        process.arguments = arguments

        let stdoutPipe = Pipe()
        let stderrPipe = Pipe()
        process.standardOutput = stdoutPipe
        process.standardError = stderrPipe

        try process.run()

        let stdoutData = stdoutPipe.fileHandleForReading.readDataToEndOfFile()
        let stderrData = stderrPipe.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()

        let stdout = String(decoding: stdoutData, as: UTF8.self)
        let stderr = String(decoding: stderrData, as: UTF8.self)

        return (process.terminationStatus, stdout, stderr)
    }

    private func destination(for platform: BuildUploadPlatform) -> String {
        switch platform {
        case .iOS: return "generic/platform=iOS"
        case .macOS: return "generic/platform=macOS"
        case .tvOS: return "generic/platform=tvOS"
        case .visionOS: return "generic/platform=visionOS"
        }
    }

    private func writeExportOptionsPlist(request: ExportRequest) throws -> String {
        var entries = """
            <key>method</key>
            <string>\(request.method.rawValue)</string>
            <key>signingStyle</key>
            <string>\(request.signingStyle.rawValue)</string>
        """
        if let teamId = request.teamId {
            entries += """

                <key>teamID</key>
                <string>\(teamId)</string>
            """
        }
        let plist = """
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
        <plist version="1.0">
        <dict>
        \(entries)
        </dict>
        </plist>
        """
        let path = FileManager.default.temporaryDirectory
            .appendingPathComponent("asc-export-options-\(UUID().uuidString).plist").path
        try plist.write(toFile: path, atomically: true, encoding: .utf8)
        return path
    }

    private func findExportedBinary(in exportPath: String) -> String? {
        let fm = FileManager.default
        guard let contents = try? fm.contentsOfDirectory(atPath: exportPath) else { return nil }
        if let ipa = contents.first(where: { $0.hasSuffix(".ipa") }) {
            return "\(exportPath)/\(ipa)"
        }
        if let pkg = contents.first(where: { $0.hasSuffix(".pkg") }) {
            return "\(exportPath)/\(pkg)"
        }
        return nil
    }
}
