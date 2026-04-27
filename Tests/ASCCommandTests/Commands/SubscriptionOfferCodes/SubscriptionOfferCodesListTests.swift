import Mockable
import Testing
@testable import ASCCommand
@testable import Domain

@Suite
struct SubscriptionOfferCodesListTests {

    @Test func `listed offer codes include name duration mode active and affordances`() async throws {
        let mockRepo = MockSubscriptionOfferCodeRepository()
        given(mockRepo).listOfferCodes(subscriptionId: .any)
            .willReturn([
                SubscriptionOfferCode(
                    id: "oc-1",
                    subscriptionId: "sub-1",
                    name: "SUMMER2024",
                    customerEligibilities: [.new, .lapsed],
                    offerEligibility: .stackable,
                    duration: .oneMonth,
                    offerMode: .freeTrial,
                    numberOfPeriods: 1,
                    isActive: true
                )
            ])

        let cmd = try SubscriptionOfferCodesList.parse(["--subscription-id", "sub-1", "--pretty"])
        let output = try await cmd.execute(repo: mockRepo)

        #expect(output == """
        {
          "data" : [
            {
              "affordances" : {
                "deactivate" : "asc subscription-offer-codes update --active false --offer-code-id oc-1",
                "listCustomCodes" : "asc subscription-offer-code-custom-codes list --offer-code-id oc-1",
                "listOfferCodes" : "asc subscription-offer-codes list --subscription-id sub-1",
                "listOneTimeCodes" : "asc subscription-offer-code-one-time-codes list --offer-code-id oc-1"
              },
              "customerEligibilities" : [
                "NEW",
                "LAPSED"
              ],
              "duration" : "ONE_MONTH",
              "id" : "oc-1",
              "isActive" : true,
              "name" : "SUMMER2024",
              "numberOfPeriods" : 1,
              "offerEligibility" : "STACKABLE",
              "offerMode" : "FREE_TRIAL",
              "subscriptionId" : "sub-1"
            }
          ]
        }
        """)
    }

    @Test func `table output includes all row fields`() async throws {
        let mockRepo = MockSubscriptionOfferCodeRepository()
        given(mockRepo).listOfferCodes(subscriptionId: .any)
            .willReturn([
                SubscriptionOfferCode(
                    id: "oc-1",
                    subscriptionId: "sub-1",
                    name: "SUMMER2024",
                    customerEligibilities: [.new],
                    offerEligibility: .stackable,
                    duration: .threeMonths,
                    offerMode: .payAsYouGo,
                    numberOfPeriods: 3,
                    isActive: true
                )
            ])

        let cmd = try SubscriptionOfferCodesList.parse(["--subscription-id", "sub-1", "--output", "table"])
        let output = try await cmd.execute(repo: mockRepo)

        #expect(output.contains("oc-1"))
        #expect(output.contains("SUMMER2024"))
        #expect(output.contains("THREE_MONTHS"))
        #expect(output.contains("PAY_AS_YOU_GO"))
        #expect(output.contains("true"))
    }
}
