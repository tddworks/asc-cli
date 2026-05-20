import ArgumentParser
import Domain
import Foundation
import Infrastructure

struct SalesReportsSummary: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "summary",
        abstract: "Aggregate daily sales reports into a single rollup (downloads, updates, in-app purchases, payers, and per-currency customer spend and developer proceeds)"
    )

    @OptionGroup var globals: GlobalOptions

    @Option(name: .long, help: "Vendor number (auto-resolved from active account if saved)")
    var vendorNumber: String?

    @Option(name: .long, help: "Start date inclusive (YYYY-MM-DD)")
    var from: String

    @Option(name: .long, help: "End date inclusive (YYYY-MM-DD)")
    var to: String

    func run() async throws {
        let repo = try ClientProvider.makeReportRepository()
        let storage = FileAuthStorage()
        print(try await execute(repo: repo, storage: storage))
    }

    func execute(repo: any ReportRepository, storage: any AuthStorage = FileAuthStorage()) async throws -> String {
        let resolvedVendorNumber = try VendorNumberResolver.resolve(explicit: vendorNumber, storage: storage)
        let dates = try expandDateRange(from: from, to: to)

        var downloads = 0
        var updates = 0
        var inAppPurchases = 0
        var customerSpend: [String: Decimal] = [:]
        var proceeds: [String: Decimal] = [:]
        var payerSKUs = Set<String>()

        for date in dates {
            let rows = try await repo.downloadSalesReport(
                vendorNumber: resolvedVendorNumber,
                reportType: .sales,
                subType: .summary,
                frequency: .daily,
                reportDate: date,
                version: nil
            )
            for row in rows {
                let units = Int(row["Units"] ?? "0") ?? 0
                let pti = row["Product Type Identifier"] ?? ""
                let price = decimal(row["Customer Price"])
                let earnings = decimal(row["Developer Proceeds"])
                let customerCurrency = trim(row["Customer Currency"])
                let proceedsCurrency = trim(row["Currency of Proceeds"])

                switch bucket(for: pti) {
                case .firstInstall: downloads += units
                case .update: updates += units
                case .inAppPurchase: inAppPurchases += units
                case .other: break
                }

                if price > 0 {
                    if !customerCurrency.isEmpty {
                        customerSpend[customerCurrency, default: 0] += price * Decimal(units)
                    }
                    if let sku = row["SKU"], !sku.isEmpty {
                        payerSKUs.insert(sku)
                    }
                }
                if earnings > 0, !proceedsCurrency.isEmpty {
                    proceeds[proceedsCurrency, default: 0] += earnings * Decimal(units)
                }
            }
        }

        let summary = Summary(
            from: from,
            to: to,
            days: dates.count,
            downloads: downloads,
            updates: updates,
            inAppPurchases: inAppPurchases,
            payers: payerSKUs.count,
            customerSpend: customerSpend,
            proceeds: proceeds
        )
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        if globals.pretty {
            encoder.outputFormatting.insert(.prettyPrinted)
        }
        let data = try encoder.encode(summary)
        return String(decoding: data, as: UTF8.self)
    }

    private enum Bucket { case firstInstall, update, inAppPurchase, other }

    private func bucket(for pti: String) -> Bucket {
        // First installs start with "1" (iOS) or "F" (macOS). 3F (Apple Watch redownload),
        // 7* (updates), and IA* (in-app purchases) are bucketed separately.
        if pti.hasPrefix("IA") { return .inAppPurchase }
        if pti.hasPrefix("7") { return .update }
        if pti.hasPrefix("1") || pti.hasPrefix("F") { return .firstInstall }
        return .other
    }

    private func decimal(_ raw: String?) -> Decimal {
        Decimal(string: (raw ?? "0").trimmingCharacters(in: .whitespaces)) ?? 0
    }

    private func trim(_ raw: String?) -> String {
        (raw ?? "").trimmingCharacters(in: .whitespaces)
    }

    private func expandDateRange(from: String, to: String) throws -> [String] {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone(identifier: "UTC")
        guard let fromDate = formatter.date(from: from), let toDate = formatter.date(from: to) else {
            throw ValidationError("Dates must be YYYY-MM-DD")
        }
        guard fromDate <= toDate else {
            throw ValidationError("--from (\(from)) must be on or before --to (\(to))")
        }
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        var dates: [String] = []
        var cursor = fromDate
        while cursor <= toDate {
            dates.append(formatter.string(from: cursor))
            cursor = calendar.date(byAdding: .day, value: 1, to: cursor)!
        }
        return dates
    }

    private struct Summary: Encodable {
        let from: String
        let to: String
        let days: Int
        let downloads: Int
        let updates: Int
        let inAppPurchases: Int
        let payers: Int
        let customerSpend: [String: Decimal]
        let proceeds: [String: Decimal]
    }
}
