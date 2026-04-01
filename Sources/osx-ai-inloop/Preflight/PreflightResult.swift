// PreflightResult.swift
// Structured result from environment preflight checks.

import Foundation

// MARK: - CheckItem

/// A single preflight check result.
public struct CheckItem: Codable, Sendable {
    /// Display name for this check.
    public let name: String

    /// Whether this check passed.
    public let passed: Bool

    /// Human-readable message explaining the result.
    public let message: String

    public init(name: String, passed: Bool, message: String) {
        self.name = name
        self.passed = passed
        self.message = message
    }
}

// MARK: - PreflightResult

/// The aggregated result of all preflight checks.
public struct PreflightResult: Sendable {
    /// True if all checks passed and the environment is compatible.
    public let isCompatible: Bool

    /// Individual check results.
    public let checks: [CheckItem]

    public init(isCompatible: Bool, checks: [CheckItem]) {
        self.isCompatible = isCompatible
        self.checks = checks
    }

    // MARK: - JSON Output

    /// Structured type for JSON serialization.
    public struct JSONOutput: Encodable {
        public let isCompatible: Bool
        public let checks: [CheckItem]
        public let summary: String

        enum CodingKeys: String, CodingKey {
            case isCompatible = "is_compatible"
            case checks
            case summary
        }
    }

    /// Convert to a JSON-serializable struct.
    public func toJSON() -> JSONOutput {
        let summary: String
        if isCompatible {
            summary = "All checks passed. Environment is compatible with Apple Intelligence."
        } else {
            let failed = checks.filter { !$0.passed }.map { $0.name }.joined(separator: ", ")
            summary = "Some checks failed: \(failed). Apple Intelligence may not be available."
        }
        return JSONOutput(isCompatible: isCompatible, checks: checks, summary: summary)
    }

    // MARK: - Human Readable Output

    /// Generate a human-readable diagnostic report.
    public func toHumanReadable() -> String {
        var lines: [String] = []
        let maxNameLength = checks.map { $0.name.count }.max() ?? 20

        for check in checks {
            let icon = check.passed ? "✓" : "✗"
            let paddedName = check.name.padding(toLength: maxNameLength, withPad: " ", startingAt: 0)
            lines.append("  \(icon) \(paddedName)  \(check.message)")
        }

        lines.append("")
        if isCompatible {
            lines.append("  Result: COMPATIBLE — Apple Intelligence is ready to use.")
        } else {
            let failedCount = checks.filter { !$0.passed }.count
            lines.append("  Result: NOT COMPATIBLE — \(failedCount) check(s) failed.")
            lines.append("")
            lines.append("  Failed checks:")
            for check in checks where !check.passed {
                lines.append("    • \(check.name): \(check.message)")
            }
        }

        return lines.joined(separator: "\n")
    }
}
