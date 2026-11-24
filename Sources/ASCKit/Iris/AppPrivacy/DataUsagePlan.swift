/// How a declaration replaces the rows Apple holds (law 3): delete those not wanted, then
/// create those missing. Rows already right are left alone.
public struct DataUsagePlan: Sendable, Equatable {
    public let deletions: [DataUsage]
    public let creations: [DataUsageEntry]

    public init(current: [DataUsage], wanted: PrivacyDeclaration) {
        let wantedEntries = wanted.entries
        let held = Set(current.map(\.entry))
        let keep = Set(wantedEntries)
        deletions = current.filter { !keep.contains($0.entry) }
        creations = wantedEntries.filter { !held.contains($0) }
    }
}
