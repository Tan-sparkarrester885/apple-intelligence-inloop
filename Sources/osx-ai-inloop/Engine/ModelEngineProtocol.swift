// ModelEngineProtocol.swift
// Protocol and shared types for model engine implementations.

import Foundation

// MARK: - GenerationOptions

/// Options to control the generation behavior.
public struct GenerationOptions: Sendable {
    /// Temperature for generation (0.0 = deterministic, 1.0 = max randomness).
    /// Pass nil to use the model's default.
    public var temperature: Double?

    /// Maximum number of tokens to generate.
    /// Pass nil to use the model's default.
    public var maxTokens: Int?

    /// Nucleus sampling probability threshold.
    public var topP: Double?

    public init(
        temperature: Double? = nil,
        maxTokens: Int? = nil,
        topP: Double? = nil
    ) {
        self.temperature = temperature
        self.maxTokens = maxTokens
        self.topP = topP
    }
}

// MARK: - GenerationResult

/// The result of a successful model generation.
public struct GenerationResult: Sendable {
    /// The generated text output.
    public let output: String

    /// The model mode that was used (e.g., "on-device").
    public let model: String

    /// Optional usage/metadata about the generation.
    public let usage: UsageInfo?

    public init(output: String, model: String, usage: UsageInfo? = nil) {
        self.output = output
        self.model = model
        self.usage = usage
    }
}

// MARK: - ModelEngine Protocol

/// Protocol for model engine implementations.
/// Conform to this protocol to provide alternative backends (real, mock, etc.)
public protocol ModelEngine: Sendable {
    /// Generate a response for the given prompt.
    ///
    /// - Parameters:
    ///   - prompt: The user prompt text.
    ///   - systemInstruction: Optional system instruction / persona.
    ///   - inputText: Optional additional input text to append.
    ///   - options: Optional generation options (temperature, max tokens, etc.).
    /// - Returns: A `GenerationResult` containing the output and metadata.
    /// - Throws: `GenerationEngineError` on failure.
    func generate(
        prompt: String,
        systemInstruction: String?,
        inputText: String?,
        options: GenerationOptions?
    ) async throws -> GenerationResult
}

// MARK: - GenerationEngineError

/// Errors thrown by model engine implementations.
public enum GenerationEngineError: Error, Sendable {
    /// The FoundationModels framework is not available on this platform.
    case frameworkUnavailable

    /// The model is not available (not eligible device, Apple Intelligence not enabled, not downloaded, etc.)
    case modelUnavailable(reason: String)

    /// An error occurred during generation (content policy, context overflow, etc.)
    case generationFailed(underlying: String)

    /// An internal error occurred.
    case internalError(message: String)

    // MARK: - Properties

    /// The exit code for this error.
    public var exitCode: AppExitCode {
        switch self {
        case .frameworkUnavailable: return .unsupportedEnvironment
        case .modelUnavailable: return .unavailableModel
        case .generationFailed: return .generationFailure
        case .internalError: return .internalError
        }
    }

    /// Convert to (code, message) pair for JSON error responses.
    public func toExitInfo() -> (code: String, message: String) {
        switch self {
        case .frameworkUnavailable:
            return (
                "UNSUPPORTED_ENVIRONMENT",
                "FoundationModels framework is not available. Requires macOS 26+ with Apple Intelligence."
            )
        case .modelUnavailable(let reason):
            return ("UNAVAILABLE_MODEL", reason)
        case .generationFailed(let underlying):
            return ("GENERATION_FAILURE", underlying)
        case .internalError(let message):
            return ("INTERNAL_ERROR", message)
        }
    }

    public var localizedDescription: String {
        let (_, message) = toExitInfo()
        return message
    }
}
