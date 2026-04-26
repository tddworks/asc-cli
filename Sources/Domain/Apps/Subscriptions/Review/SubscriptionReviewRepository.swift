import Foundation
import Mockable

@Mockable
public protocol SubscriptionReviewRepository: Sendable {
    func getReviewScreenshot(subscriptionId: String) async throws -> SubscriptionReviewScreenshot?
    func uploadReviewScreenshot(subscriptionId: String, fileURL: URL) async throws -> SubscriptionReviewScreenshot
    func deleteReviewScreenshot(screenshotId: String) async throws
}
