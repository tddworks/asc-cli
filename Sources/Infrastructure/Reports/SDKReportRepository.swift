@preconcurrency import AppStoreConnect_Swift_SDK
import Domain
import Foundation

public struct SDKReportRepository: ReportRepository, @unchecked Sendable {
    private let client: any APIClient

    public init(client: any APIClient) {
        self.client = client
    }

    public func downloadSalesReport(
        vendorNumber: String,
        reportType: SalesReportType,
        subType: SalesReportSubType,
        frequency: ReportFrequency,
        reportDate: String?,
        version: String?
    ) async throws -> [[String: String]] {
        let sdkReportType = mapSalesReportType(reportType)
        let sdkSubType = mapSalesReportSubType(subType)
        let sdkFrequency = mapFrequency(frequency)

        let endpoint = APIEndpoint.v1.salesReports.get(parameters: .init(
            filterVendorNumber: [vendorNumber],
            filterReportType: [sdkReportType],
            filterReportSubType: [sdkSubType],
            filterFrequency: [sdkFrequency],
            filterReportDate: reportDate.map { [$0] },
            filterVersion: version.map { [$0] }
        ))

        let data: Data = try await client.request(endpoint)
        let decompressed = try data.gunzipped()
        guard let tsv = String(data: decompressed, encoding: .utf8) else {
            throw ReportError.invalidEncoding
        }
        return TSVParser.parse(tsv)
    }

    public func downloadFinanceReport(
        vendorNumber: String,
        reportType: FinanceReportType,
        regionCode: String,
        reportDate: String
    ) async throws -> [[String: String]] {
        let sdkReportType = mapFinanceReportType(reportType)

        let endpoint = APIEndpoint.v1.financeReports.get(parameters: .init(
            filterVendorNumber: [vendorNumber],
            filterReportType: [sdkReportType],
            filterRegionCode: [regionCode],
            filterReportDate: [reportDate]
        ))

        let data: Data = try await client.request(endpoint)
        let decompressed = try data.gunzipped()
        guard let tsv = String(data: decompressed, encoding: .utf8) else {
            throw ReportError.invalidEncoding
        }
        return TSVParser.parse(tsv)
    }

    // MARK: - Mappers

    private func mapSalesReportType(_ type: SalesReportType) -> APIEndpoint.V1.SalesReports.GetParameters.FilterReportType {
        switch type {
        case .sales: return .sales
        case .preOrder: return .preOrder
        case .newsstand: return .newsstand
        case .subscription: return .subscription
        case .subscriptionEvent: return .subscriptionEvent
        case .subscriber: return .subscriber
        case .subscriptionOfferCodeRedemption: return .subscriptionOfferCodeRedemption
        case .installs: return .installs
        case .firstAnnual: return .firstAnnual
        case .winBackEligibility: return .winBackEligibility
        }
    }

    private func mapSalesReportSubType(_ subType: SalesReportSubType) -> APIEndpoint.V1.SalesReports.GetParameters.FilterReportSubType {
        switch subType {
        case .summary: return .summary
        case .detailed: return .detailed
        case .summaryInstallType: return .summaryInstallType
        case .summaryTerritory: return .summaryTerritory
        case .summaryChannel: return .summaryChannel
        }
    }

    private func mapFrequency(_ frequency: ReportFrequency) -> APIEndpoint.V1.SalesReports.GetParameters.FilterFrequency {
        switch frequency {
        case .daily: return .daily
        case .weekly: return .weekly
        case .monthly: return .monthly
        case .yearly: return .yearly
        }
    }

    private func mapFinanceReportType(_ type: FinanceReportType) -> APIEndpoint.V1.FinanceReports.GetParameters.FilterReportType {
        switch type {
        case .financial: return .financial
        case .financeDetail: return .financeDetail
        }
    }
}

public enum ReportError: Error {
    case invalidEncoding
}
