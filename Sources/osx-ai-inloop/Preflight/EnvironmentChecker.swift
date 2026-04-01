// EnvironmentChecker.swift
// Runs all preflight checks to verify the environment supports Apple Intelligence.

import Foundation

#if canImport(Darwin)
import Darwin
#endif

#if canImport(FoundationModels)
import FoundationModels
#endif

/// Runs all environment and capability checks.
public enum EnvironmentChecker {

    // MARK: - Run All Checks

    /// Run all preflight checks and return a structured result.
    public static func run() async -> PreflightResult {
        var checks: [CheckItem] = []

        // 1. macOS platform check
        checks.append(checkMacOSPlatform())

        // 2. macOS version check
        checks.append(checkMacOSVersion())

        // 3. Apple Silicon check
        checks.append(checkAppleSilicon())

        // 4. Foundation Models framework availability
        checks.append(checkFoundationModelsFramework())

        // 5. Apple Intelligence availability (async — requires FoundationModels)
        checks.append(await checkAppleIntelligenceAvailability())

        let isCompatible = checks.allSatisfy { $0.passed }

        return PreflightResult(isCompatible: isCompatible, checks: checks)
    }

    // MARK: - Individual Checks

    /// Check that we are running on macOS.
    private static func checkMacOSPlatform() -> CheckItem {
        #if os(macOS)
        return CheckItem(
            name: "Operating System",
            passed: true,
            message: "Running on macOS."
        )
        #else
        return CheckItem(
            name: "Operating System",
            passed: false,
            message: "Not running on macOS. Apple Intelligence requires macOS 26+."
        )
        #endif
    }

    /// Check that the macOS version is 26.0 or later.
    private static func checkMacOSVersion() -> CheckItem {
        let version = ProcessInfo.processInfo.operatingSystemVersion
        let isSupported = version.majorVersion >= 26

        if isSupported {
            return CheckItem(
                name: "macOS Version",
                passed: true,
                message: "macOS \(version.majorVersion).\(version.minorVersion).\(version.patchVersion) — compatible."
            )
        } else {
            return CheckItem(
                name: "macOS Version",
                passed: false,
                message: "macOS \(version.majorVersion).\(version.minorVersion).\(version.patchVersion) detected. macOS 26.0+ required."
            )
        }
    }

    /// Check that the process is running on Apple Silicon.
    private static func checkAppleSilicon() -> CheckItem {
        #if arch(arm64)
        return CheckItem(
            name: "Apple Silicon",
            passed: true,
            message: "Apple Silicon (arm64) detected."
        )
        #elseif os(macOS)
        // Additional check using sysctlbyname to get hardware machine info
        var machineBuffer = [CChar](repeating: 0, count: 256)
        var size = machineBuffer.count
        let result = sysctlbyname("hw.machine", &machineBuffer, &size, nil, 0)
        if result == 0 {
            let machine = String(cString: machineBuffer)
            if machine.lowercased().hasPrefix("arm") {
                return CheckItem(
                    name: "Apple Silicon",
                    passed: true,
                    message: "Apple Silicon (\(machine)) detected."
                )
            } else {
                return CheckItem(
                    name: "Apple Silicon",
                    passed: false,
                    message: "Non-Apple Silicon hardware (\(machine)) detected. Apple Intelligence requires Apple Silicon."
                )
            }
        }
        return CheckItem(
            name: "Apple Silicon",
            passed: false,
            message: "Could not determine hardware architecture. Apple Intelligence may not be available."
        )
        #else
        return CheckItem(
            name: "Apple Silicon",
            passed: false,
            message: "Not running on macOS. Cannot verify Apple Silicon."
        )
        #endif
    }

    /// Check that the FoundationModels framework is importable.
    private static func checkFoundationModelsFramework() -> CheckItem {
        #if canImport(FoundationModels)
        return CheckItem(
            name: "FoundationModels Framework",
            passed: true,
            message: "FoundationModels framework is available."
        )
        #else
        return CheckItem(
            name: "FoundationModels Framework",
            passed: false,
            message: "FoundationModels framework is not available. Requires macOS 26+ and Xcode 26+."
        )
        #endif
    }

    /// Check Apple Intelligence model availability via FoundationModels.
    private static func checkAppleIntelligenceAvailability() async -> CheckItem {
        #if canImport(FoundationModels)
        let availability = SystemLanguageModel.default.availability
        switch availability {
        case .available:
            let contextSize = SystemLanguageModel.default.contextSize
            return CheckItem(
                name: "Apple Intelligence",
                passed: true,
                message: "Apple Intelligence is available and ready. Context window: \(contextSize) tokens."
            )
        case .unavailable(let reason):
            let message: String
            switch reason {
            case .deviceNotEligible:
                message = "Device is not eligible for Apple Intelligence. Requires Apple Silicon (M-series)."
            case .appleIntelligenceNotEnabled:
                message = "Apple Intelligence is not enabled. Go to System Settings > Apple Intelligence & Siri to enable it."
            case .modelNotReady:
                message = "The Apple Intelligence model is still downloading. Check progress in System Settings."
            @unknown default:
                message = "Apple Intelligence is unavailable: unknown reason."
            }
            return CheckItem(
                name: "Apple Intelligence",
                passed: false,
                message: message
            )
        @unknown default:
            return CheckItem(
                name: "Apple Intelligence",
                passed: false,
                message: "Apple Intelligence availability is unknown."
            )
        }
        #else
        return CheckItem(
            name: "Apple Intelligence",
            passed: false,
            message: "Cannot check Apple Intelligence — FoundationModels framework not available on this platform."
        )
        #endif
    }
}
