import Foundation

/// Apple refused to add an item to, or submit, a review submission. `reasons` are the
/// specific problems Apple listed (missing screenshots, pricing, privacy answers, …),
/// which its headline message only points at.
public enum ReviewSubmissionError: Error, Equatable, Sendable, CustomStringConvertible, LocalizedError {
    case refused(message: String, reasons: [String])

    public var description: String {
        switch self {
        case .refused(let message, let reasons):
            (["Apple refused the review submission: \(message)"] + reasons.map { "  - \($0)" })
                .joined(separator: "\n")
        }
    }

    public var errorDescription: String? { description }
}
