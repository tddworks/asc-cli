import Foundation

/// Parse an ISO8601 string, accepting either a full timestamp
/// (`2026-11-01T00:00:00Z`) or a date-only form (`2026-11-01`).
///
/// The date-only form is interpreted as midnight UTC.
func parseFlexibleISO8601(_ value: String) -> Date? {
    let full = ISO8601DateFormatter()
    full.formatOptions = [.withInternetDateTime]
    if let date = full.date(from: value) {
        return date
    }

    let dateOnly = ISO8601DateFormatter()
    dateOnly.formatOptions = [.withFullDate]
    return dateOnly.date(from: value)
}
