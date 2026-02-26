/// Simplified readiness report for ASCBar's UI — mapped from the `asc versions check-readiness` CLI output.
public struct VersionReadinessResult: Sendable, Equatable {
    public let versionId: String
    public let versionString: String
    public let isReadyToSubmit: Bool
    /// Human-readable build label, e.g. "2.1.0 (102)". Nil when no build is attached.
    public let buildLabel: String?
    public let mustFix: [ReadinessItem]
    public let shouldFix: [ReadinessItem]
    public let passing: [ReadinessItem]

    public init(
        versionId: String,
        versionString: String,
        isReadyToSubmit: Bool,
        buildLabel: String?,
        mustFix: [ReadinessItem],
        shouldFix: [ReadinessItem],
        passing: [ReadinessItem]
    ) {
        self.versionId = versionId
        self.versionString = versionString
        self.isReadyToSubmit = isReadyToSubmit
        self.buildLabel = buildLabel
        self.mustFix = mustFix
        self.shouldFix = shouldFix
        self.passing = passing
    }
}

public struct ReadinessItem: Sendable, Equatable, Identifiable {
    public let id: String
    public let title: String
    public let description: String
    public let fixAction: ReadinessFixAction?

    public init(id: String, title: String, description: String, fixAction: ReadinessFixAction? = nil) {
        self.id = id
        self.title = title
        self.description = description
        self.fixAction = fixAction
    }
}

public enum ReadinessFixAction: Sendable, Equatable {
    case copyCommand(String)
    case navigateToLocalizations
}
