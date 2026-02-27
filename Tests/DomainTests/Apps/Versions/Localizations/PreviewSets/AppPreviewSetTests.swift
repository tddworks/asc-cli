import Foundation
import Testing
@testable import Domain

@Suite
struct AppPreviewSetTests {

    // MARK: - Parent ID

    @Test func `preview set carries localizationId`() {
        let set = MockRepositoryFactory.makePreviewSet(id: "set-1", localizationId: "loc-42")
        #expect(set.localizationId == "loc-42")
    }

    // MARK: - Computed properties

    @Test func `preview set with zero previews is empty`() {
        let set = MockRepositoryFactory.makePreviewSet(previewsCount: 0)
        #expect(set.isEmpty == true)
    }

    @Test func `preview set with previews is not empty`() {
        let set = MockRepositoryFactory.makePreviewSet(previewsCount: 3)
        #expect(set.isEmpty == false)
    }

    @Test func `iphone67 preview set device category is iPhone`() {
        let set = MockRepositoryFactory.makePreviewSet(previewType: .iphone67)
        #expect(set.deviceCategory == .iPhone)
    }

    @Test func `ipadPro3gen129 preview set device category is iPad`() {
        let set = MockRepositoryFactory.makePreviewSet(previewType: .ipadPro3gen129)
        #expect(set.deviceCategory == .iPad)
    }

    @Test func `desktop preview set device category is mac`() {
        let set = MockRepositoryFactory.makePreviewSet(previewType: .desktop)
        #expect(set.deviceCategory == .mac)
    }

    @Test func `appleTV preview set device category is appleTV`() {
        let set = MockRepositoryFactory.makePreviewSet(previewType: .appleTV)
        #expect(set.deviceCategory == .appleTV)
    }

    @Test func `appleVisionPro preview set device category is appleVisionPro`() {
        let set = MockRepositoryFactory.makePreviewSet(previewType: .appleVisionPro)
        #expect(set.deviceCategory == .appleVisionPro)
    }

    // MARK: - Affordances

    @Test func `preview set affordances include listPreviews command`() {
        let set = MockRepositoryFactory.makePreviewSet(id: "set-1")
        #expect(set.affordances["listPreviews"] == "asc app-previews list --set-id set-1")
    }

    @Test func `preview set affordances include listPreviewSets command`() {
        let set = MockRepositoryFactory.makePreviewSet(id: "set-1", localizationId: "loc-1")
        #expect(set.affordances["listPreviewSets"] == "asc app-preview-sets list --localization-id loc-1")
    }

    // MARK: - Codable round-trip

    @Test func `codable round-trip preserves all fields`() throws {
        let original = MockRepositoryFactory.makePreviewSet(
            id: "set-1", localizationId: "loc-1", previewType: .iphone67, previewsCount: 2
        )
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(AppPreviewSet.self, from: data)
        #expect(decoded == original)
    }
}
