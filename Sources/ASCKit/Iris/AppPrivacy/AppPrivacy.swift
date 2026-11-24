/// An app's privacy label — the App Privacy page: "Data Not Collected" or the data types it
/// collects, and whether that answer is published. One per app; the aggregate.
public struct AppPrivacy: Sendable, Equatable {
    /// Parent and identity: there is one label per app.
    public let appId: String
    public let dataCollection: DataCollection
    public let isPublished: Bool
    /// When it was last published (Apple's `lastPublished`); nil = never.
    public let lastPublishedAt: String?

    public init(appId: String, dataCollection: DataCollection, isPublished: Bool, lastPublishedAt: String?) {
        self.appId = appId
        self.dataCollection = dataCollection
        self.isPublished = isPublished
        self.lastPublishedAt = lastPublishedAt
    }

    /// The label Apple's rows make (law 1).
    public init(appId: String, dataUsages: [DataUsage], isPublished: Bool, lastPublishedAt: String?) {
        let collected = CollectedData.grouping(dataUsages)
        let collection: DataCollection
        if !collected.isEmpty {
            collection = .collected(collected)
        } else if dataUsages.contains(where: { $0.protection == .notCollected }) {
            collection = .notCollected
        } else {
            collection = .notAnswered
        }
        self.init(appId: appId, dataCollection: collection, isPublished: isPublished, lastPublishedAt: lastPublishedAt)
    }

    public var isAnswered: Bool { dataCollection != .notAnswered }
    public var isNotCollected: Bool { dataCollection == .notCollected }
    /// App Review refuses a submission until the label is answered and published (law 7).
    public var blocksSubmission: Bool { !(isAnswered && isPublished) }

    /// Replaces the label with `declaration` (law 3). It stays a draft until published (law 4).
    public func declare(_ declaration: PrivacyDeclaration, session: IrisSession, repo: any IrisAppPrivacyRepository) async throws -> AppPrivacy {
        try declaration.validate()
        let plan = DataUsagePlan(current: try await repo.listDataUsages(session: session, appId: appId), wanted: declaration)
        for usage in plan.deletions {
            try await repo.deleteDataUsage(session: session, dataUsageId: usage.id)
        }
        for entry in plan.creations {
            try await repo.createDataUsage(session: session, appId: appId, entry: entry)
        }
        return try await repo.fetchPrivacy(session: session, appId: appId)
    }

    /// Makes the label live — only once something is declared (law 5).
    public func publish(session: IrisSession, repo: any IrisAppPrivacyRepository) async throws -> AppPrivacy {
        guard isAnswered else { throw AppPrivacyError.nothingDeclared(appId: appId) }
        try await repo.publish(session: session, appId: appId)
        return try await repo.fetchPrivacy(session: session, appId: appId)
    }
}

extension AppPrivacy: Codable {
    private enum CodingKeys: String, CodingKey {
        case appId, dataCollection, collectedData, isAnswered, isPublished, blocksSubmission, lastPublishedAt
    }

    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let collection: DataCollection
        switch try c.decode(String.self, forKey: .dataCollection) {
        case "NOT_COLLECTED": collection = .notCollected
        case "COLLECTED": collection = .collected(try c.decode([CollectedData].self, forKey: .collectedData))
        default: collection = .notAnswered
        }
        self.init(
            appId: try c.decode(String.self, forKey: .appId),
            dataCollection: collection,
            isPublished: try c.decode(Bool.self, forKey: .isPublished),
            lastPublishedAt: try c.decodeIfPresent(String.self, forKey: .lastPublishedAt)
        )
    }

    public func encode(to encoder: any Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(appId, forKey: .appId)
        try c.encode(dataCollection.wireValue, forKey: .dataCollection)
        if case .collected(let data) = dataCollection {
            try c.encode(data, forKey: .collectedData)
        }
        try c.encode(isAnswered, forKey: .isAnswered)
        try c.encode(isPublished, forKey: .isPublished)
        try c.encode(blocksSubmission, forKey: .blocksSubmission)
        try c.encodeIfPresent(lastPublishedAt, forKey: .lastPublishedAt)
    }
}

extension AppPrivacy: AffordanceProviding {
    public var structuredAffordances: [Affordance] {
        let app = ["app-id": appId]
        var items = [
            Affordance(key: "get", command: "iris app-privacy", action: "get", params: app),
            Affordance(key: "declare", command: "iris app-privacy", action: "declare", params: app.merging(["file": "<privacy.json>"]) { $1 }),
        ]
        if !isAnswered {
            items.append(Affordance(key: "declareNotCollected", command: "iris app-privacy", action: "declare", params: app, flags: ["not-collected"]))
        }
        if isAnswered && !isPublished {
            items.append(Affordance(key: "publish", command: "iris app-privacy", action: "publish", params: app))
        }
        return items
    }
}

extension AppPrivacy: Presentable {
    public static var tableHeaders: [String] { ["App ID", "Data Collection", "Published", "Blocks Submission"] }
    public var tableRow: [String] {
        [appId, dataCollection.wireValue, isPublished ? "yes" : "no", blocksSubmission ? "yes" : "no"]
    }
}
