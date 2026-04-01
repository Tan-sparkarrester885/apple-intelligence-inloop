// ExitCodes.swift
// Defines exit codes for the osx-ai-inloop CLI.
// Used throughout the codebase for consistent error handling.

import Foundation
import ArgumentParser

/// Exit codes for the osx-ai-inloop CLI.
///
/// Follows Unix conventions:
/// - 0: Success
/// - 1-127: Application-defined error codes
///
/// These codes are documented in the README and can be used by calling scripts
/// to determine the nature of any failure.
public enum AppExitCode: Int32, CaseIterable, Sendable {
    /// Operation completed successfully.
    case success = 0

    /// Invalid or missing arguments were provided.
    case invalidArguments = 1

    /// The current environment does not support Apple Intelligence
    /// (wrong OS version, wrong architecture, etc.)
    case unsupportedEnvironment = 2

    /// The language model is unavailable
    /// (Apple Intelligence not enabled, model not downloaded, etc.)
    case unavailableModel = 3

    /// A generation error occurred
    /// (content policy violation, context overflow, etc.)
    case generationFailure = 4

    /// An unexpected internal error occurred.
    case internalError = 5

    // MARK: - Properties

    /// Human-readable name for this exit code.
    public var name: String {
        switch self {
        case .success: return "Success"
        case .invalidArguments: return "Invalid Arguments"
        case .unsupportedEnvironment: return "Unsupported Environment"
        case .unavailableModel: return "Unavailable Model"
        case .generationFailure: return "Generation Failure"
        case .internalError: return "Internal Error"
        }
    }

    /// Short machine-readable code (SCREAMING_SNAKE_CASE).
    public var code: String {
        switch self {
        case .success: return "SUCCESS"
        case .invalidArguments: return "INVALID_ARGUMENTS"
        case .unsupportedEnvironment: return "UNSUPPORTED_ENVIRONMENT"
        case .unavailableModel: return "UNAVAILABLE_MODEL"
        case .generationFailure: return "GENERATION_FAILURE"
        case .internalError: return "INTERNAL_ERROR"
        }
    }

    /// Description of when this exit code is used.
    public var description: String {
        switch self {
        case .success:
            return "Command completed successfully."
        case .invalidArguments:
            return "Invalid or missing command-line arguments."
        case .unsupportedEnvironment:
            return "The environment does not meet Apple Intelligence requirements."
        case .unavailableModel:
            return "The Apple Intelligence model is not available or not ready."
        case .generationFailure:
            return "The model failed to generate a response."
        case .internalError:
            return "An unexpected internal error occurred."
        }
    }

    // MARK: - Conversion

    /// Convert to an ArgumentParser ExitCode for use with ParsableCommand.
    public func toArgumentParserExitCode() -> ArgumentParser.ExitCode {
        ArgumentParser.ExitCode(rawValue: self.rawValue)
    }

    /// Initialize from an Int32 value.
    public init?(int32 value: Int32) {
        self.init(rawValue: value)
    }
}

// MARK: - ArgumentParser.ExitCode Extension

extension ArgumentParser.ExitCode {
    /// Create an ArgumentParser ExitCode from an AppExitCode.
    public static func from(_ appCode: AppExitCode) -> ArgumentParser.ExitCode {
        ArgumentParser.ExitCode(rawValue: appCode.rawValue)
    }
}
