import Foundation

public struct PrivateKeyLoader: Sendable {

    public init() {}

    public func loadFromFile(path: String) throws -> String {
        let expandedPath = NSString(string: path).expandingTildeInPath
        let url = URL(fileURLWithPath: expandedPath)
        return try String(contentsOf: url, encoding: .utf8)
    }

    public func loadFromBase64(_ base64String: String) throws -> String {
        guard let data = Data(base64Encoded: base64String) else {
            throw Domain.AuthError.invalidPrivateKey("Invalid base64 encoding")
        }
        guard let pem = String(data: data, encoding: .utf8) else {
            throw Domain.AuthError.invalidPrivateKey("Could not decode PEM from base64")
        }
        return pem
    }
}
