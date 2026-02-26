import Foundation
import Domain

// MARK: - Private CLI response types

private struct DataResponse<T: Decodable>: Decodable {
    let data: [T]
}

private struct CLIVersionReadiness: Decodable {
    let id: String
    let appId: String
    let versionString: String
    let isReadyToSubmit: Bool
    let stateCheck: CLICheck
    let buildCheck: CLIBuildCheck
    let pricingCheck: CLICheck
    let localizationCheck: CLILocalizationCheck
    let reviewContactCheck: CLICheck
}

private struct CLICheck: Decodable {
    let pass: Bool
    let message: String?
}

private struct CLIBuildCheck: Decodable {
    let linked: Bool
    let valid: Bool
    let notExpired: Bool
    let pass: Bool
    let buildVersion: String?
}

private struct CLILocalizationCheck: Decodable {
    let pass: Bool
    let localizations: [CLILocalizationReadiness]
}

private struct CLILocalizationReadiness: Decodable {
    let locale: String
    let isPrimary: Bool
    let hasDescription: Bool
    let hasWhatsNew: Bool
    let screenshotSetCount: Int
}

private struct CLILocalizationItem: Decodable {
    let id: String
    let locale: String
    let whatsNew: String?
}

// MARK: - Repository

/// Implements `VersionDetailRepository` by delegating to the `asc` CLI.
public final class CLIVersionDetailRepository: VersionDetailRepository, @unchecked Sendable {
    private let executor: any CLIExecutor

    public init(executor: any CLIExecutor = DefaultCLIExecutor()) {
        self.executor = executor
    }

    public func fetchReadiness(versionId: String) async throws -> VersionReadinessResult {
        let output = try await executor.execute(
            "asc", args: ["versions", "check-readiness", "--version-id", versionId, "--output", "json"]
        )
        let response = try JSONDecoder().decode(
            DataResponse<CLIVersionReadiness>.self, from: Data(output.utf8)
        )
        guard let raw = response.data.first else {
            throw CLIVersionDetailError.emptyResponse
        }
        return mapReadiness(raw, versionId: versionId)
    }

    public func fetchLocalizations(versionId: String) async throws -> [LocalizationSummary] {
        let output = try await executor.execute(
            "asc", args: ["version-localizations", "list", "--version-id", versionId, "--output", "json"]
        )
        let response = try JSONDecoder().decode(
            DataResponse<CLILocalizationItem>.self, from: Data(output.utf8)
        )
        return response.data.enumerated().map { index, loc in
            LocalizationSummary(
                id: loc.id,
                locale: loc.locale,
                whatsNew: loc.whatsNew,
                isPrimary: index == 0
            )
        }
    }

    public func updateWhatsNew(localizationId: String, text: String) async throws {
        _ = try await executor.execute(
            "asc", args: ["version-localizations", "update",
                          "--localization-id", localizationId,
                          "--whats-new", text]
        )
    }

    // MARK: - Mapping

    private func mapReadiness(_ raw: CLIVersionReadiness, versionId: String) -> VersionReadinessResult {
        var mustFix: [ReadinessItem] = []
        var shouldFix: [ReadinessItem] = []
        var passing: [ReadinessItem] = []

        // State check (MUST FIX)
        let stateItem = ReadinessItem(
            id: "state",
            title: "Version State",
            description: raw.stateCheck.message ?? "Version is in an editable state"
        )
        if raw.stateCheck.pass { passing.append(stateItem) } else { mustFix.append(stateItem) }

        // Build check (MUST FIX)
        let buildDesc = raw.buildCheck.linked
            ? (raw.buildCheck.buildVersion ?? "Build linked")
            : "No build attached"
        let buildFixAction: ReadinessFixAction? = raw.buildCheck.pass
            ? nil
            : .copyCommand("asc builds list --app-id \(raw.appId)")
        let buildItem = ReadinessItem(
            id: "build",
            title: "Build Attached",
            description: buildDesc,
            fixAction: buildFixAction
        )
        if raw.buildCheck.pass { passing.append(buildItem) } else { mustFix.append(buildItem) }

        // Pricing check (MUST FIX)
        let pricingItem = ReadinessItem(
            id: "pricing",
            title: "Pricing",
            description: raw.pricingCheck.message ?? "Price schedule configured"
        )
        if raw.pricingCheck.pass { passing.append(pricingItem) } else { mustFix.append(pricingItem) }

        // Primary localization check (MUST FIX)
        let primaryLoc = raw.localizationCheck.localizations.first { $0.isPrimary }
        let primaryLocDesc: String
        if let primary = primaryLoc {
            if primary.hasDescription && primary.screenshotSetCount > 0 {
                primaryLocDesc = "Primary locale (\(primary.locale)) is complete"
            } else {
                var issues: [String] = []
                if !primary.hasDescription { issues.append("missing description") }
                if primary.screenshotSetCount == 0 { issues.append("no screenshots") }
                primaryLocDesc = issues.joined(separator: ", ")
            }
        } else {
            primaryLocDesc = "No localizations found"
        }
        let locItem = ReadinessItem(
            id: "localization",
            title: "Primary Localization",
            description: primaryLocDesc,
            fixAction: raw.localizationCheck.pass ? nil : .navigateToLocalizations
        )
        if raw.localizationCheck.pass { passing.append(locItem) } else { mustFix.append(locItem) }

        // Review contact check (SHOULD FIX)
        let reviewItem = ReadinessItem(
            id: "reviewContact",
            title: "Review Contact",
            description: raw.reviewContactCheck.message ?? "Review contact is set"
        )
        if raw.reviewContactCheck.pass { passing.append(reviewItem) } else { shouldFix.append(reviewItem) }

        // What's New check (SHOULD FIX if any locale is missing)
        let missingWhatsNew = raw.localizationCheck.localizations.filter { !$0.hasWhatsNew }
        if !raw.localizationCheck.localizations.isEmpty {
            if missingWhatsNew.isEmpty {
                passing.append(ReadinessItem(
                    id: "whatsNew",
                    title: "What's New Text",
                    description: "Set for all locales"
                ))
            } else {
                let locales = missingWhatsNew.map(\.locale).joined(separator: ", ")
                shouldFix.append(ReadinessItem(
                    id: "whatsNew",
                    title: "What's New Text",
                    description: "Missing in: \(locales)",
                    fixAction: .navigateToLocalizations
                ))
            }
        }

        return VersionReadinessResult(
            versionId: versionId,
            versionString: raw.versionString,
            isReadyToSubmit: raw.isReadyToSubmit,
            buildLabel: raw.buildCheck.buildVersion,
            mustFix: mustFix,
            shouldFix: shouldFix,
            passing: passing
        )
    }
}

enum CLIVersionDetailError: Error {
    case emptyResponse
}
