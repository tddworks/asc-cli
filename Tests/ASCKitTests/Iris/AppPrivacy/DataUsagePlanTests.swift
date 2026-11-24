import Testing
@testable import ASCKit

/// Law 3: declaring replaces the label, touching only the rows that change.
@Suite
struct DataUsagePlanTests {
    private func usage(_ id: String, _ category: String?, _ purpose: String?, _ protection: DataProtection) -> DataUsage {
        DataUsage(id: id, appId: "1234567890", category: category.map(DataCategory.init(rawValue:)),
                  purpose: purpose.map(DataPurpose.init(rawValue:)), protection: protection)
    }

    @Test func `should delete every collected row when the app now collects nothing`() {
        let current = [usage("u-1", "CRASH_DATA", "ANALYTICS", .notLinkedToYou), usage("u-2", "CRASH_DATA", "APP_FUNCTIONALITY", .notLinkedToYou)]

        let plan = DataUsagePlan(current: current, wanted: .notCollected)

        #expect(plan.deletions == current)
        #expect(plan.creations == [DataUsageEntry(category: nil, purpose: nil, protection: .notCollected)])
    }

    @Test func `should leave rows that are already right alone`() {
        let current = [usage("u-1", "CRASH_DATA", "ANALYTICS", .notLinkedToYou), usage("u-2", "CRASH_DATA", "OTHER_PURPOSES", .notLinkedToYou)]
        let wanted = PrivacyDeclaration.collected([
            CollectedData(category: .init(rawValue: "CRASH_DATA"), purposes: [.init(rawValue: "ANALYTICS"), .init(rawValue: "APP_FUNCTIONALITY")],
                          isLinkedToYou: false, isUsedToTrackYou: false),
        ])

        let plan = DataUsagePlan(current: current, wanted: wanted)

        #expect(plan.deletions == [usage("u-2", "CRASH_DATA", "OTHER_PURPOSES", .notLinkedToYou)])
        #expect(plan.creations == [DataUsageEntry(category: .init(rawValue: "CRASH_DATA"), purpose: .init(rawValue: "APP_FUNCTIONALITY"), protection: .notLinkedToYou)])
    }

    @Test func `should change nothing when the label already says it`() {
        let plan = DataUsagePlan(current: [usage("u-1", nil, nil, .notCollected)], wanted: .notCollected)

        #expect(plan.deletions.isEmpty)
        #expect(plan.creations.isEmpty)
    }
}
