import Mockable
import Testing
@testable import ASCCommand
@testable import Domain

@Suite
struct SubscriptionOffersDeleteTests {

    @Test func `delete introductory offer calls repo with offer id`() async throws {
        let mockRepo = MockSubscriptionIntroductoryOfferRepository()
        given(mockRepo).deleteIntroductoryOffer(offerId: .any).willReturn(())

        let cmd = try SubscriptionOffersDelete.parse(["--offer-id", "offer-1"])
        try await cmd.execute(repo: mockRepo)

        verify(mockRepo).deleteIntroductoryOffer(offerId: .value("offer-1")).called(1)
    }
}
