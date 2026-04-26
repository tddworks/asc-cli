import Foundation
import Mockable

@Mockable
public protocol InAppPurchaseReviewRepository: Sendable {
    func getReviewScreenshot(iapId: String) async throws -> InAppPurchaseReviewScreenshot?
    func uploadReviewScreenshot(iapId: String, fileURL: URL) async throws -> InAppPurchaseReviewScreenshot
    func deleteReviewScreenshot(screenshotId: String) async throws

    func listImages(iapId: String) async throws -> [InAppPurchasePromotionalImage]
    func uploadImage(iapId: String, fileURL: URL) async throws -> InAppPurchasePromotionalImage
    func deleteImage(imageId: String) async throws
}
