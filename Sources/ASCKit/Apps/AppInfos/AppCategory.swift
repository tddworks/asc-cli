import Mockable

public struct AppCategory: Sendable, Equatable, Identifiable, Codable {
    public let id: String
    /// Platforms this category is available for (e.g. ["IOS", "MAC_OS"]).
    public let platforms: [String]
    /// Parent category ID — nil for top-level categories, non-nil for subcategories.
    public let parentId: String?

    public init(id: String, platforms: [String] = [], parentId: String? = nil) {
        self.id = id
        self.platforms = platforms
        self.parentId = parentId
    }
}

extension AppCategory: Presentable {
    public static var tableHeaders: [String] {
        ["ID", "Platforms", "Parent ID"]
    }
    public var tableRow: [String] {
        [id, platforms.joined(separator: ","), parentId ?? "-"]
    }
}

extension AppCategory: AffordanceProviding {
    public var structuredAffordances: [Affordance] {
        [
            Affordance(key: "listCategories", command: "app-categories", action: "list", params: [:]),
        ]
    }
}

@Mockable
public protocol AppCategoryRepository: Sendable {
    func listCategories(platform: String?) async throws -> [AppCategory]
    func getCategory(id: String) async throws -> AppCategory
}
