import Foundation

public struct XcodeCloudWorkflow: Sendable, Equatable, Identifiable, Codable {
    public let id: String
    public let productId: String
    public let name: String
    public let description: String?
    public let isEnabled: Bool
    public let isLockedForEditing: Bool
    public let containerFilePath: String?

    public init(
        id: String, productId: String, name: String,
        description: String? = nil, isEnabled: Bool, isLockedForEditing: Bool,
        containerFilePath: String? = nil
    ) {
        self.id = id
        self.productId = productId
        self.name = name
        self.description = description
        self.isEnabled = isEnabled
        self.isLockedForEditing = isLockedForEditing
        self.containerFilePath = containerFilePath
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(String.self, forKey: .id)
        self.productId = try container.decode(String.self, forKey: .productId)
        self.name = try container.decode(String.self, forKey: .name)
        self.description = try container.decodeIfPresent(String.self, forKey: .description)
        self.isEnabled = try container.decode(Bool.self, forKey: .isEnabled)
        self.isLockedForEditing = try container.decode(Bool.self, forKey: .isLockedForEditing)
        self.containerFilePath = try container.decodeIfPresent(String.self, forKey: .containerFilePath)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(productId, forKey: .productId)
        try container.encode(name, forKey: .name)
        try container.encodeIfPresent(description, forKey: .description)
        try container.encode(isEnabled, forKey: .isEnabled)
        try container.encode(isLockedForEditing, forKey: .isLockedForEditing)
        try container.encodeIfPresent(containerFilePath, forKey: .containerFilePath)
    }

    private enum CodingKeys: String, CodingKey {
        case id, productId, name, description, isEnabled, isLockedForEditing, containerFilePath
    }
}

extension XcodeCloudWorkflow: AffordanceProviding {
    public var affordances: [String: String] {
        var cmds: [String: String] = [
            "listBuildRuns": "asc xcode-cloud builds list --workflow-id \(id)",
            "listWorkflows": "asc xcode-cloud workflows list --product-id \(productId)",
        ]
        if isEnabled {
            cmds["startBuild"] = "asc xcode-cloud builds start --workflow-id \(id)"
        }
        return cmds
    }
}
