import Crypto
import Foundation

/// Apple's variant of RFC 9019 hashcash. Apple started gating `signin/complete` on this
/// header (`X-Apple-HC`) in early 2023 — without it, `idmsa.apple.com` returns 401 with
/// no clue why, manifesting as the misleading "Incorrect Apple Account email or password"
/// error that has bitten every reverse-engineered Apple-auth client.
///
/// Format: `1:<bits>:<YYYYMMDDhhmmss>:<challenge>::<counter>`
///
/// Apple deviates from the RFC in two ways:
///   1. The "Ext" slot (between challenge and counter) is empty, leaving `::`.
///   2. The counter is a decimal string, not base64.
///
/// We iterate `counter` from 0 until `SHA1(string)` has `bits` leading zero bits.
/// Reference: fastlane spaceship's reverse-engineered implementation.
public enum AppleHashcash {

    public static func compute(challenge: String, bits: Int) -> String {
        let date = currentDateString()
        var counter = 0
        while true {
            let candidate = "1:\(bits):\(date):\(challenge)::\(counter)"
            let digest = Insecure.SHA1.hash(data: Data(candidate.utf8))
            if leadingZeroBitCount(Data(digest)) >= bits {
                return candidate
            }
            counter += 1
        }
    }

    private static func currentDateString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMddHHmmss"
        formatter.timeZone = TimeZone(identifier: "UTC")
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter.string(from: Date())
    }

    private static func leadingZeroBitCount(_ data: Data) -> Int {
        var count = 0
        for byte in data {
            if byte == 0 { count += 8; continue }
            count += byte.leadingZeroBitCount
            return count
        }
        return count
    }
}
