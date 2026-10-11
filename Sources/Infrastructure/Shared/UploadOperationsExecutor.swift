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

    /// Mirrors the reserve/upload step of every ASC asset: set headers verbatim, and throw
    /// rather than leave a partial file with App Store Connect — before sending anything when
    /// an operation lacks its method, URL or byte range, and on any non-2xx part.
    public func upload(fileURL: URL, operations: [UploadOperation]) async throws {
        let parts = try operations.map { operation -> (method: String, url: URL, offset: Int, length: Int, headers: [HTTPHeader]) in
            guard let urlString = operation.url,
                  let url = URL(string: urlString),
                  let method = operation.method,
                  let offset = operation.offset,
                  let length = operation.length
            else {
                throw APIError.unknown("App Store Connect sent an upload part without a method, URL or byte range")
            }
            return (method, url, offset, length, operation.requestHeaders ?? [])
        }

        let handle = try FileHandle(forReadingFrom: fileURL)
        defer { try? handle.close() }

        for (method, url, offset, length, headers) in parts {

            try handle.seek(toOffset: UInt64(offset))
            let chunk = try handle.read(upToCount: length) ?? Data()

            var request = URLRequest(url: url)
            request.httpMethod = method
            for header in headers {
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
