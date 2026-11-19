import Testing
@testable import ASCKit

@Suite
struct SalesReportTypeTests {

    @Test func `SALES has correct raw value`() {
        #expect(SalesReportType.sales.rawValue == "SALES")
    }

    @Test func `PRE_ORDER has correct raw value`() {
        #expect(SalesReportType.preOrder.rawValue == "PRE_ORDER")
    }

    @Test func `NEWSSTAND has correct raw value`() {
        #expect(SalesReportType.newsstand.rawValue == "NEWSSTAND")
    }

    @Test func `SUBSCRIPTION has correct raw value`() {
        #expect(SalesReportType.subscription.rawValue == "SUBSCRIPTION")
    }

    @Test func `SUBSCRIPTION_EVENT has correct raw value`() {
        #expect(SalesReportType.subscriptionEvent.rawValue == "SUBSCRIPTION_EVENT")
    }

    @Test func `SUBSCRIBER has correct raw value`() {
        #expect(SalesReportType.subscriber.rawValue == "SUBSCRIBER")
    }

    @Test func `SUBSCRIPTION_OFFER_CODE_REDEMPTION has correct raw value`() {
        #expect(SalesReportType.subscriptionOfferCodeRedemption.rawValue == "SUBSCRIPTION_OFFER_CODE_REDEMPTION")
    }

    @Test func `INSTALLS has correct raw value`() {
        #expect(SalesReportType.installs.rawValue == "INSTALLS")
    }

    @Test func `FIRST_ANNUAL has correct raw value`() {
        #expect(SalesReportType.firstAnnual.rawValue == "FIRST_ANNUAL")
    }

    @Test func `WIN_BACK_ELIGIBILITY has correct raw value`() {
        #expect(SalesReportType.winBackEligibility.rawValue == "WIN_BACK_ELIGIBILITY")
    }

    @Test func `initializes from raw value`() {
        #expect(SalesReportType(rawValue: "SALES") == .sales)
    }

    @Test func `initializes from CLI argument`() {
        #expect(SalesReportType(cliArgument: "SALES") == .sales)
        #expect(SalesReportType(cliArgument: "sales") == .sales)
        #expect(SalesReportType(cliArgument: "INVALID") == nil)
    }
}

@Suite
struct SalesReportSubTypeTests {

    @Test func `SUMMARY has correct raw value`() {
        #expect(SalesReportSubType.summary.rawValue == "SUMMARY")
    }

    @Test func `DETAILED has correct raw value`() {
        #expect(SalesReportSubType.detailed.rawValue == "DETAILED")
    }

    @Test func `SUMMARY_INSTALL_TYPE has correct raw value`() {
        #expect(SalesReportSubType.summaryInstallType.rawValue == "SUMMARY_INSTALL_TYPE")
    }

    @Test func `SUMMARY_TERRITORY has correct raw value`() {
        #expect(SalesReportSubType.summaryTerritory.rawValue == "SUMMARY_TERRITORY")
    }

    @Test func `SUMMARY_CHANNEL has correct raw value`() {
        #expect(SalesReportSubType.summaryChannel.rawValue == "SUMMARY_CHANNEL")
    }

    @Test func `initializes from CLI argument`() {
        #expect(SalesReportSubType(cliArgument: "SUMMARY") == .summary)
        #expect(SalesReportSubType(cliArgument: "summary") == .summary)
        #expect(SalesReportSubType(cliArgument: "INVALID") == nil)
    }
}

@Suite
struct ReportFrequencyTests {

    @Test func `DAILY has correct raw value`() {
        #expect(ReportFrequency.daily.rawValue == "DAILY")
    }

    @Test func `WEEKLY has correct raw value`() {
        #expect(ReportFrequency.weekly.rawValue == "WEEKLY")
    }

    @Test func `MONTHLY has correct raw value`() {
        #expect(ReportFrequency.monthly.rawValue == "MONTHLY")
    }

    @Test func `YEARLY has correct raw value`() {
        #expect(ReportFrequency.yearly.rawValue == "YEARLY")
    }

    @Test func `initializes from CLI argument`() {
        #expect(ReportFrequency(cliArgument: "DAILY") == .daily)
        #expect(ReportFrequency(cliArgument: "daily") == .daily)
        #expect(ReportFrequency(cliArgument: "INVALID") == nil)
    }
}

@Suite
struct FinanceReportTypeTests {

    @Test func `FINANCIAL has correct raw value`() {
        #expect(FinanceReportType.financial.rawValue == "FINANCIAL")
    }

    @Test func `FINANCE_DETAIL has correct raw value`() {
        #expect(FinanceReportType.financeDetail.rawValue == "FINANCE_DETAIL")
    }

    @Test func `initializes from CLI argument`() {
        #expect(FinanceReportType(cliArgument: "FINANCIAL") == .financial)
        #expect(FinanceReportType(cliArgument: "financial") == .financial)
        #expect(FinanceReportType(cliArgument: "INVALID") == nil)
    }
}
