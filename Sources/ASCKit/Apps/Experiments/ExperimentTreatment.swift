/// One variant of the product page inside a Product Page Optimization test
/// (ASC API: `appStoreVersionExperimentTreatments`). A test has up to three.
public struct ExperimentTreatment: Sendable, Equatable, Identifiable {
    public let id: String
    /// Parent experiment identifier — injected by Infrastructure
    public let experimentId: String
    public let name: String
    /// Name of the alternate app icon asset this treatment tests, if any.
    public let appIconName: String?
    /// ISO-8601 timestamp set once this treatment was promoted to the live product page.
    public let promotedDate: String?

    public init(
        id: String,
        experimentId: String,
        name: String,
        appIconName: String? = nil,
        promotedDate: String? = nil
    ) {
        self.id = id
        self.experimentId = experimentId
        self.name = name
        self.appIconName = appIconName
        self.promotedDate = promotedDate
    }
}

extension ExperimentTreatment: Codable {
    enum CodingKeys: String, CodingKey {
        case id, experimentId, name, appIconName, promotedDate
    }

    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        experimentId = try c.decode(String.self, forKey: .experimentId)
        name = try c.decode(String.self, forKey: .name)
        appIconName = try c.decodeIfPresent(String.self, forKey: .appIconName)
        promotedDate = try c.decodeIfPresent(String.self, forKey: .promotedDate)
    }

    public func encode(to encoder: any Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(experimentId, forKey: .experimentId)
        try c.encode(name, forKey: .name)
        try c.encodeIfPresent(appIconName, forKey: .appIconName)
        try c.encodeIfPresent(promotedDate, forKey: .promotedDate)
    }
}

extension ExperimentTreatment: Presentable {
    public static var tableHeaders: [String] {
        ["ID", "Name", "App Icon", "Promoted"]
    }
    public var tableRow: [String] {
        [id, name, appIconName ?? "-", promotedDate ?? "-"]
    }
}

extension ExperimentTreatment: AffordanceProviding {
    public var structuredAffordances: [Affordance] {
        [
            Affordance(key: "listSiblings", command: "experiment-treatments", action: "list", params: ["experiment-id": experimentId]),
            Affordance(key: "listLocalizations", command: "experiment-treatment-localizations", action: "list", params: ["treatment-id": id]),
            Affordance(key: "createLocalization", command: "experiment-treatment-localizations", action: "create",
                       params: ["treatment-id": id, "locale": "<locale>"]),
            Affordance(key: "update", command: "experiment-treatments", action: "update", params: ["treatment-id": id]),
            Affordance(key: "delete", command: "experiment-treatments", action: "delete", params: ["treatment-id": id]),
        ]
    }
}
