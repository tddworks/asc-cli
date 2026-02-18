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
}
