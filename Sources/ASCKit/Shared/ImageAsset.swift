import Foundation

public struct ImageAsset: Sendable, Codable, Equatable {
    public let templateUrl: String
    public let width: Int
    public let height: Int

    public init(templateUrl: String, width: Int, height: Int) {
        self.templateUrl = templateUrl
        self.width = width
        self.height = height
    }

    public func url(maxSize size: Int, format: String = "png") -> URL? {
        let raw = templateUrl
            .replacingOccurrences(of: "{w}", with: String(size))
            .replacingOccurrences(of: "{h}", with: String(size))
            .replacingOccurrences(of: "{f}", with: format)
        return URL(string: raw)
    }
}