import Foundation
import Testing
@testable import Domain
@testable import Infrastructure

@Suite
struct GzipDecompressionTests {

    @Test func `decompresses valid gzip data`() throws {
        let original = "Hello, World!"
        let gzipped = try gzipCompress(original.data(using: .utf8)!)
        let decompressed = try gzipped.gunzipped()
        #expect(String(data: decompressed, encoding: .utf8) == "Hello, World!")
    }

    @Test func `decompresses multi-line TSV gzip data`() throws {
        let tsv = "Provider\tSKU\tUnits\nAPPLE\tcom.example\t10\n"
        let gzipped = try gzipCompress(tsv.data(using: .utf8)!)
        let decompressed = try gzipped.gunzipped()
        #expect(String(data: decompressed, encoding: .utf8) == tsv)
    }

    @Test func `throws on invalid gzip data`() {
        let badData = Data([0x00, 0x01, 0x02, 0x03])
        #expect(throws: (any Error).self) {
            try badData.gunzipped()
        }
    }
}

@Suite
struct TSVParserTests {

    @Test func `parses single row TSV`() {
        let tsv = "Provider\tSKU\tUnits\nAPPLE\tcom.example\t10"
        let rows = TSVParser.parse(tsv)
        #expect(rows.count == 1)
        #expect(rows[0]["Provider"] == "APPLE")
        #expect(rows[0]["SKU"] == "com.example")
        #expect(rows[0]["Units"] == "10")
    }

    @Test func `parses multiple rows TSV`() {
        let tsv = "Provider\tSKU\tUnits\nAPPLE\tcom.a\t10\nAPPLE\tcom.b\t5"
        let rows = TSVParser.parse(tsv)
        #expect(rows.count == 2)
        #expect(rows[0]["SKU"] == "com.a")
        #expect(rows[1]["SKU"] == "com.b")
    }

    @Test func `handles trailing newline`() {
        let tsv = "Provider\tSKU\nAPPLE\tcom.a\n"
        let rows = TSVParser.parse(tsv)
        #expect(rows.count == 1)
    }

    @Test func `returns empty for header only TSV`() {
        let tsv = "Provider\tSKU"
        let rows = TSVParser.parse(tsv)
        #expect(rows.isEmpty)
    }

    @Test func `returns empty for empty string`() {
        let rows = TSVParser.parse("")
        #expect(rows.isEmpty)
    }

    @Test func `handles row with fewer columns than headers`() {
        let tsv = "A\tB\tC\n1\t2"
        let rows = TSVParser.parse(tsv)
        #expect(rows.count == 1)
        #expect(rows[0]["A"] == "1")
        #expect(rows[0]["B"] == "2")
        #expect(rows[0]["C"] == nil)
    }
}

@Suite
struct SDKReportRepositoryDownloadSalesReportTests {

    @Test func `downloadSalesReport decompresses and parses TSV`() async throws {
        let tsv = "Provider\tSKU\tUnits\nAPPLE\tcom.example\t10\n"
        let gzipped = try gzipCompress(tsv.data(using: .utf8)!)

        let stub = StubAPIClient()
        stub.willReturn(gzipped)

        let repo = SDKReportRepository(client: stub)
        let rows = try await repo.downloadSalesReport(
            vendorNumber: "123",
            reportType: .sales,
            subType: .summary,
            frequency: .daily,
            reportDate: nil,
            version: nil
        )

        #expect(rows.count == 1)
        #expect(rows[0]["Provider"] == "APPLE")
        #expect(rows[0]["SKU"] == "com.example")
        #expect(rows[0]["Units"] == "10")
    }

    @Test func `downloadSalesReport sends filter[version] when version provided`() async throws {
        let tsv = "Provider\tSKU\tUnits\nAPPLE\tcom.example\t16\n"
        let gzipped = try gzipCompress(tsv.data(using: .utf8)!)

        let stub = StubAPIClient()
        stub.willReturn(gzipped)

        let repo = SDKReportRepository(client: stub)
        _ = try await repo.downloadSalesReport(
            vendorNumber: "123",
            reportType: .sales,
            subType: .summary,
            frequency: .daily,
            reportDate: "2026-05-18",
            version: "1_4"
        )

        let query = stub.lastQuery ?? []
        #expect(query.contains(where: { $0.0 == "filter[version]" && $0.1 == "1_4" }))
    }

    @Test func `downloadSalesReport omits filter[version] when version is nil`() async throws {
        let tsv = "Provider\tSKU\tUnits\nAPPLE\tcom.example\t1\n"
        let gzipped = try gzipCompress(tsv.data(using: .utf8)!)

        let stub = StubAPIClient()
        stub.willReturn(gzipped)

        let repo = SDKReportRepository(client: stub)
        _ = try await repo.downloadSalesReport(
            vendorNumber: "123",
            reportType: .sales,
            subType: .summary,
            frequency: .daily,
            reportDate: nil,
            version: nil
        )

        let query = stub.lastQuery ?? []
        #expect(!query.contains(where: { $0.0 == "filter[version]" }))
    }
}

@Suite
struct SDKReportRepositoryDownloadFinanceReportTests {

    @Test func `downloadFinanceReport decompresses and parses TSV`() async throws {
        let tsv = "Region\tUnits\tProceeds\nUS\t100\t699.00\n"
        let gzipped = try gzipCompress(tsv.data(using: .utf8)!)

        let stub = StubAPIClient()
        stub.willReturn(gzipped)

        let repo = SDKReportRepository(client: stub)
        let rows = try await repo.downloadFinanceReport(
            vendorNumber: "123",
            reportType: .financial,
            regionCode: "US",
            reportDate: "2024-01"
        )

        #expect(rows.count == 1)
        #expect(rows[0]["Region"] == "US")
        #expect(rows[0]["Proceeds"] == "699.00")
    }
}

// MARK: - Test helper: gzip compress using Process (gunzip can decompress it)

private func gzipCompress(_ data: Data) throws -> Data {
    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/usr/bin/gzip")
    process.arguments = ["-c"]

    let inputPipe = Pipe()
    let outputPipe = Pipe()
    process.standardInput = inputPipe
    process.standardOutput = outputPipe

    try process.run()
    inputPipe.fileHandleForWriting.write(data)
    inputPipe.fileHandleForWriting.closeFile()
    process.waitUntilExit()

    return outputPipe.fileHandleForReading.readDataToEndOfFile()
}
