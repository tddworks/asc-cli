@preconcurrency import AppStoreConnect_Swift_SDK
import Domain
import Foundation

/// Sends a file's bytes to the upload URLs App Store Connect hands out when an asset is
/// reserved. Each operation names a byte range; parts are read from disk one at a time so
/// large videos never sit in memory whole.
public struct UploadOperationsExecutor: Sendable {
    private let http: any HTTPPerforming

    public init(http: any HTTPPerforming = URLSession.shared) {
        self.http = http
    }

    /// Mirrors the reserve/upload step of every ASC asset: skip operations missing a
    /// method/url/range, set headers verbatim, and throw on non-2xx so a failed part
    /// surfaces instead of leaving a partial file with App Store Connect.
    public func upload(fileURL: URL, operations: [UploadOperation]) async throws {
        let handle = try FileHandle(forReadingFrom: fileURL)
        defer { try? handle.close() }

        for operation in operations {
            guard let urlString = operation.url,
                  let url = URL(string: urlString),
                  let method = operation.method,
                  let offset = operation.offset,
                  let length = operation.length
            else { continue }

            try handle.seek(toOffset: UInt64(offset))
            let chunk = try handle.read(upToCount: length) ?? Data()

            var request = URLRequest(url: url)
            request.httpMethod = method
            for header in operation.requestHeaders ?? [] {
                if let name = header.name {
                    request.setValue(header.value, forHTTPHeaderField: name)
                }
            }
            request.httpBody = chunk

            let (_, response) = try await http.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse,
                  200..<300 ~= httpResponse.statusCode
            else {
                throw APIError.unknown("Upload of bytes \(offset)..<\(offset + length) failed")
            }
        }
    }
}
