import Testing
@testable import Domain

@Suite
struct AppStoreVersionStateTests {

    @Test
    func `readyForSale is live`() {
        #expect(AppStoreVersionState.readyForSale.isLive == true)
    }

    @Test
    func `prepareForSubmission is not live`() {
        #expect(AppStoreVersionState.prepareForSubmission.isLive == false)
    }

    @Test
    func `prepareForSubmission is editable`() {
        #expect(AppStoreVersionState.prepareForSubmission.isEditable == true)
    }

    @Test
    func `developerRejected is editable`() {
        #expect(AppStoreVersionState.developerRejected.isEditable == true)
    }

    @Test
    func `readyForSale is not editable`() {
        #expect(AppStoreVersionState.readyForSale.isEditable == false)
    }

    @Test
    func `waitingForReview is pending`() {
        #expect(AppStoreVersionState.waitingForReview.isPending == true)
    }

    @Test
    func `inReview is pending`() {
        #expect(AppStoreVersionState.inReview.isPending == true)
    }

    @Test
    func `readyForSale is not pending`() {
        #expect(AppStoreVersionState.readyForSale.isPending == false)
    }

    @Test
    func `raw values match App Store Connect API strings`() {
        #expect(AppStoreVersionState.prepareForSubmission.rawValue == "PREPARE_FOR_SUBMISSION")
        #expect(AppStoreVersionState.readyForSale.rawValue == "READY_FOR_SALE")
        #expect(AppStoreVersionState.inReview.rawValue == "IN_REVIEW")
        #expect(AppStoreVersionState.rejected.rawValue == "REJECTED")
    }

    @Test
    func `round trips from raw value`() {
        let state = AppStoreVersionState(rawValue: "READY_FOR_SALE")
        #expect(state == .readyForSale)
    }

    @Test
    func `unknown raw value returns nil`() {
        #expect(AppStoreVersionState(rawValue: "UNKNOWN_STATE") == nil)
    }

    // MARK: - isEditable (all states)

    @Test(arguments: [
        AppStoreVersionState.prepareForSubmission,
        .developerRejected,
        .rejected,
        .metadataRejected,
    ])
    func `editable states are editable`(state: AppStoreVersionState) {
        #expect(state.isEditable == true)
    }

    @Test(arguments: [
        AppStoreVersionState.waitingForReview,
        .inReview,
        .pendingDeveloperRelease,
        .pendingAppleRelease,
        .processingForAppStore,
        .readyForSale,
        .removedFromSale,
        .developerRemovedFromSale,
        .invalidBinary,
        .waitingForExportCompliance,
        .pendingContract,
    ])
    func `non-editable states are not editable`(state: AppStoreVersionState) {
        #expect(state.isEditable == false)
    }

    // MARK: - isPending (all states)

    @Test(arguments: [
        AppStoreVersionState.waitingForReview,
        .inReview,
        .pendingDeveloperRelease,
        .pendingAppleRelease,
        .processingForAppStore,
        .waitingForExportCompliance,
    ])
    func `pending states are pending`(state: AppStoreVersionState) {
        #expect(state.isPending == true)
    }

    @Test(arguments: [
        AppStoreVersionState.prepareForSubmission,
        .readyForSale,
        .developerRejected,
        .rejected,
        .metadataRejected,
        .removedFromSale,
        .developerRemovedFromSale,
        .invalidBinary,
        .pendingContract,
    ])
    func `non-pending states are not pending`(state: AppStoreVersionState) {
        #expect(state.isPending == false)
    }

    // MARK: - displayName

    @Test(arguments: zip(
        AppStoreVersionState.allCases,
        [
            "Prepare for Submission",
            "Waiting for Review",
            "In Review",
            "Pending Developer Release",
            "Pending Apple Release",
            "Processing for App Store",
            "Ready for Sale",
            "Developer Rejected",
            "Rejected",
            "Metadata Rejected",
            "Removed from Sale",
            "Developer Removed from Sale",
            "Invalid Binary",
            "Waiting for Export Compliance",
            "Pending Contract",
        ]
    ))
    func `displayName returns human readable string`(state: AppStoreVersionState, expected: String) {
        #expect(state.displayName == expected)
    }
}
