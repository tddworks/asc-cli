import Foundation

public enum XcodeCloudProductType: String, Sendable, Equatable, Codable {
    case app = "APP"
    case framework = "FRAMEWORK"
}

public struct XcodeCloudProduct: Sendable, Equatable, Identifiable, Codable {
    public let id: String
    public let appId: String
    public let name: String
    public let productType: XcodeCloudProductType
    public let createdDate: Date?

    public init(id: String, appId: String, name: String, productType: XcodeCloudProductType, createdDate: Date? = nil) {
        self.id = id
        self.appId = appId
        self.name = name
        self.productType = productType
        self.createdDate = createdDate
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(String.self, forKey: .id)
        self.appId = try container.decode(String.self, forKey: .appId)
        self.name = try container.decode(String.self, forKey: .name)
        self.productType = try container.decode(XcodeCloudProductType.self, forKey: .productType)
        self.createdDate = try container.decodeIfPresent(Date.self, forKey: .createdDate)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(appId, forKey: .appId)
        try container.encode(name, forKey: .name)
        try container.encode(productType, forKey: .productType)
        try container.encodeIfPresent(createdDate, forKey: .createdDate)
    }

    private enum CodingKeys: String, CodingKey {
        case id, appId, name, productType, createdDate
    }
}

extension XcodeCloudProduct: AffordanceProviding {
    public var affordances: [String: String] {
        [
            "listWorkflows": "asc xcode-cloud workflows list --product-id \(id)",
            "listProducts": "asc xcode-cloud products list --app-id \(appId)",
        ]
    }
}
