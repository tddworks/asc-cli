/// A locale included in a treatment (ASC API: `appStoreVersionExperimentTreatmentLocalizations`).
/// Screenshot sets and app preview sets for the treatment hang off this resource.
public struct ExperimentTreatmentLocalization: Sendable, Equatable, Identifiable, Codable {
    public let id: String
    /// Parent treatment identifier — injected by Infrastructure
    public let treatmentId: String
    public let locale: String

    public init(id: String, treatmentId: String, locale: String) {
        self.id = id
        self.treatmentId = treatmentId
        self.locale = locale
    }
}

extension ExperimentTreatmentLocalization: Presentable {
    public static var tableHeaders: [String] { ["ID", "Locale"] }
    public var tableRow: [String] { [id, locale] }
}

extension ExperimentTreatmentLocalization: AffordanceProviding {
    public var structuredAffordances: [Affordance] {
        [
            Affordance(key: "listSiblings", command: "experiment-treatment-localizations", action: "list", params: ["treatment-id": treatmentId]),
            Affordance(key: "delete", command: "experiment-treatment-localizations", action: "delete", params: ["localization-id": id]),
            Affordance(key: "listPlacements", command: "asset-placements", action: "list", params: ["treatment-localization-id": id]),
        ]
    }
}
