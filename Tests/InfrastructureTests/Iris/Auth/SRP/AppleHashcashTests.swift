import Crypto
import Foundation
import Testing
@testable import Infrastructure

@Suite
struct AppleHashcashTests {

    @Test func `hashcash output starts with version 1 then bits`() {
        let hc = AppleHashcash.compute(challenge: "ABC123", bits: 11)
        let parts = hc.split(separator: ":", omittingEmptySubsequences: false)
        #expect(parts.count == 6)        // version : bits : date : challenge : <empty> : counter
        #expect(parts[0] == "1")
        #expect(parts[1] == "11")
        #expect(parts[3] == "ABC123")
        #expect(parts[4] == "")          // Apple's variant has nothing in the Ext slot
    }

    @Test func `hashcash SHA1 has at least the requested leading zero bits`() {
        // The defining property of Apple's hashcash: SHA1 of the formatted string must
        // have `bits` leading zero bits. We verify across a few bit settings to make
        // sure the search loop terminates and the output is valid.
        for bits in [8, 11] {
            let hc = AppleHashcash.compute(challenge: "challenge-\(bits)", bits: bits)
            let digest = Insecure.SHA1.hash(data: Data(hc.utf8))
            let leadingZeros = countLeadingZeroBits(Data(digest))
            #expect(leadingZeros >= bits)
        }
    }

    @Test func `hashcash counter is decimal not base64`() {
        // Apple deviates from RFC 9019 — they encode the counter as a decimal string,
        // not base64. The last segment must therefore be all digits.
        let hc = AppleHashcash.compute(challenge: "X", bits: 8)
        let counter = hc.split(separator: ":").last!
        #expect(counter.allSatisfy { $0.isASCII && $0.isNumber })
    }

    private func countLeadingZeroBits(_ data: Data) -> Int {
        var count = 0
        for byte in data {
            if byte == 0 { count += 8; continue }
            count += byte.leadingZeroBitCount
            break
        }
        return count
    }
}
