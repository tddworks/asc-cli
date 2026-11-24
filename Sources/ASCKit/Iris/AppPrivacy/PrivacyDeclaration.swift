/// What a developer declares: no data at all, or the data types the app collects. The type
/// can't hold both (law 2). As JSON — a `--file` or a REST body — it is
/// `{"notCollected": true}` or `{"collectedData": [...]}`, the shape `get` shows.
public enum PrivacyDeclaration: Sendable, Equatable {
    case notCollected
    case collected([CollectedData])

    /// The rows Apple stores for it (law 1).
    public var entries: [DataUsageEntry] {
        switch self {
        case .notCollected: [DataUsageEntry(category: nil, purpose: nil, protection: .notCollected)]
        case .collected(let data): data.flatMap(\.entries)
        }
    }

    /// Refuses what asc won't send, before anything reaches Apple (law 6).
    public func validate() throws {
        guard case .collected(let data) = self else { return }
        guard !data.isEmpty else { throw AppPrivacyError.noDataTypes }
        var seen: Set<DataCategory> = []
        for item in data {
            guard item.category.isRecognized else { throw AppPrivacyError.unknownCategory(item.category.rawValue) }
            guard seen.insert(item.category).inserted else { throw AppPrivacyError.duplicateCategory(item.category.rawValue) }
            guard !item.purposes.isEmpty else { throw AppPrivacyError.noPurposes(category: item.category.rawValue) }
            var purposes: Set<DataPurpose> = []
            for purpose in item.purposes {
                guard purpose.isRecognized else { throw AppPrivacyError.unknownPurpose(purpose.rawValue) }
                guard purposes.insert(purpose).inserted else {
                    throw AppPrivacyError.duplicatePurpose(category: item.category.rawValue, purpose: purpose.rawValue)
                }
            }
        }
    }
}

extension PrivacyDeclaration: Decodable {
    private enum CodingKeys: String, CodingKey {
        case notCollected, collectedData
    }

    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let notCollected = try c.decodeIfPresent(Bool.self, forKey: .notCollected) ?? false
        let data = try c.decodeIfPresent([CollectedData].self, forKey: .collectedData)
        switch (notCollected, data) {
        case (true, nil): self = .notCollected
        case (false, let data?): self = .collected(data)
        default:
            throw DecodingError.dataCorrupted(.init(
                codingPath: [], debugDescription: #"Give either "notCollected": true or "collectedData": [...], not both"#
            ))
        }
    }
}
