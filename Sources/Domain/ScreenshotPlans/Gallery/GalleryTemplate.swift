import Foundation

/// Defines WHERE things go in each screen type — pure layout, no colors.
///
/// A gallery template contains a `ScreenTemplate` for each screen type
/// (hero, feature, social). Same template works with any palette.
public struct GalleryTemplate: Sendable, Equatable, Identifiable {
    public let id: String
    public let name: String
    public let screens: [ScreenType: ScreenTemplate]

    public init(
        id: String,
        name: String,
        screens: [ScreenType: ScreenTemplate] = [:]
    ) {
        self.id = id
        self.name = name
        self.screens = screens
    }
}

// MARK: - Codable
// Custom coding so `screens` serializes as {"hero": {...}, "feature": {...}}
// instead of Swift's default [key, value, key, value] array encoding.

extension GalleryTemplate: Codable {
    private enum CodingKeys: String, CodingKey {
        case id, name, screens
    }

    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        name = try c.decode(String.self, forKey: .name)
        let raw = try c.decode([String: ScreenTemplate].self, forKey: .screens)
        var mapped: [ScreenType: ScreenTemplate] = [:]
        for (key, value) in raw {
            guard let screenType = ScreenType(rawValue: key) else { continue }
            mapped[screenType] = value
        }
        screens = mapped
    }

    public func encode(to encoder: any Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(name, forKey: .name)
        let raw = Dictionary(uniqueKeysWithValues: screens.map { ($0.key.rawValue, $0.value) })
        try c.encode(raw, forKey: .screens)
    }
}

// MARK: - Presentable

extension GalleryTemplate: Presentable {
    public static var tableHeaders: [String] {
        ["ID", "Name", "Screen Types"]
    }
    public var tableRow: [String] {
        [id, name, screens.keys.map(\.rawValue).sorted().joined(separator: ", ")]
    }
}

// MARK: - Affordances

extension GalleryTemplate: AffordanceProviding {
    public var affordances: [String: String] {
        [
            "detail": "asc app-shots gallery-templates get --id \(id)",
            "listAll": "asc app-shots gallery-templates list",
        ]
    }
}
