/// One data type an app collects, as the App Privacy page asks it: what it's used for,
/// whether it's linked to the user, whether it tracks them (law 1).
public struct CollectedData: Sendable, Equatable, Codable {
    public let category: DataCategory
    public let purposes: [DataPurpose]
    public let isLinkedToYou: Bool
    public let isUsedToTrackYou: Bool

    public init(category: DataCategory, purposes: [DataPurpose], isLinkedToYou: Bool, isUsedToTrackYou: Bool) {
        self.category = category
        self.purposes = purposes
        self.isLinkedToYou = isLinkedToYou
        self.isUsedToTrackYou = isUsedToTrackYou
    }

    /// The rows Apple stores for it: one per purpose, plus a purpose-less one when it tracks.
    var entries: [DataUsageEntry] {
        let protection: DataProtection = isLinkedToYou ? .linkedToYou : .notLinkedToYou
        var rows = purposes.map { DataUsageEntry(category: category, purpose: $0, protection: protection) }
        if isUsedToTrackYou {
            rows.append(DataUsageEntry(category: category, purpose: nil, protection: .usedToTrackYou))
        }
        return rows
    }

    /// Apple's rows joined back into one data type each, by category then purpose.
    static func grouping(_ usages: [DataUsage]) -> [CollectedData] {
        let byCategory = Dictionary(grouping: usages.filter { $0.category != nil }, by: { $0.category! })
        return byCategory.keys.sorted { $0.rawValue < $1.rawValue }.map { category in
            let rows = byCategory[category]!
            return CollectedData(
                category: category,
                purposes: Set(rows.compactMap(\.purpose)).sorted { $0.rawValue < $1.rawValue },
                isLinkedToYou: rows.contains { $0.protection == .linkedToYou },
                isUsedToTrackYou: rows.contains { $0.protection == .usedToTrackYou }
            )
        }
    }
}

/// What the label says about collection.
public enum DataCollection: Sendable, Equatable {
    /// Nothing declared yet.
    case notAnswered
    /// "Data Not Collected" — the whole label (law 2).
    case notCollected
    case collected([CollectedData])

    var wireValue: String {
        switch self {
        case .notAnswered: "NOT_ANSWERED"
        case .notCollected: "NOT_COLLECTED"
        case .collected: "COLLECTED"
        }
    }
}
