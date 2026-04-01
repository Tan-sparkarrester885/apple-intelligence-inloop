// ResponsePayload.swift
// Codable response types for osx-ai-inloop stdout output.

import Foundation

// MARK: - UsageInfo

/// Optional usage/metadata information about the generation.
public struct UsageInfo: Codable, Sendable {
    /// Total number of tokens in the prompt (if available).
    public var promptTokens: Int?

    /// Total number of tokens in the completion (if available).
    public var completionTokens: Int?

    /// Total tokens used (prompt + completion).
    public var totalTokens: Int?

    /// Wall-clock duration of the generation in seconds.
    public var durationSeconds: Double?

    public init(
        promptTokens: Int? = nil,
        completionTokens: Int? = nil,
        totalTokens: Int? = nil,
        durationSeconds: Double? = nil
    ) {
        self.promptTokens = promptTokens
        self.completionTokens = completionTokens
        self.totalTokens = totalTokens
        self.durationSeconds = durationSeconds
    }

    enum CodingKeys: String, CodingKey {
        case promptTokens = "prompt_tokens"
        case completionTokens = "completion_tokens"
        case totalTokens = "total_tokens"
        case durationSeconds = "duration_seconds"
    }
}

// MARK: - SuccessResponse

/// A successful generation response.
///
/// JSON shape:
/// ```json
/// {
///   "ok": true,
///   "model": "on-device",
///   "output": "...",
///   "usage": { ... },
///   "warnings": []
/// }
/// ```
public struct SuccessResponse: Codable, Sendable {
    /// Always true for a success response.
    public let ok: Bool

    /// The model mode used for generation.
    public let model: String

    /// The generated text output.
    public let output: String

    /// Optional usage metadata.
    public let usage: UsageInfo?

    /// Optional warnings about the generation (e.g., truncation).
    public let warnings: [String]?

    public init(
        ok: Bool = true,
        model: String,
        output: String,
        usage: UsageInfo? = nil,
        warnings: [String]? = nil
    ) {
        self.ok = ok
        self.model = model
        self.output = output
        self.usage = usage
        self.warnings = warnings
    }

    // MARK: - Factory Methods

    /// Create a simple success response with just the output text.
    public static func make(model: String, output: String) -> SuccessResponse {
        SuccessResponse(ok: true, model: model, output: output, usage: nil, warnings: nil)
    }

    /// Create a success response with timing metadata.
    public static func make(
        model: String,
        output: String,
        durationSeconds: Double,
        warnings: [String]? = nil
    ) -> SuccessResponse {
        let usage = UsageInfo(durationSeconds: durationSeconds)
        return SuccessResponse(ok: true, model: model, output: output, usage: usage, warnings: warnings)
    }
}

// MARK: - ErrorDetail

/// Details about an error condition.
public struct ErrorDetail: Codable, Sendable {
    /// Machine-readable error code in SCREAMING_SNAKE_CASE.
    public let code: String

    /// Human-readable error message.
    public let message: String

    public init(code: String, message: String) {
        self.code = code
        self.message = message
    }
}

// MARK: - ErrorResponse

/// An error response.
///
/// JSON shape:
/// ```json
/// {
///   "ok": false,
///   "error": {
///     "code": "UNSUPPORTED_ENVIRONMENT",
///     "message": "..."
///   }
/// }
/// ```
public struct ErrorResponse: Codable, Sendable {
    /// Always false for an error response.
    public let ok: Bool

    /// The error details.
    public let error: ErrorDetail

    public init(ok: Bool = false, error: ErrorDetail) {
        self.ok = ok
        self.error = error
    }

    // MARK: - Factory Methods

    /// Create an error response with a code and message.
    public static func make(code: String, message: String) -> ErrorResponse {
        ErrorResponse(ok: false, error: ErrorDetail(code: code, message: message))
    }

    /// Create an error response for invalid arguments.
    public static func invalidArguments(_ message: String) -> ErrorResponse {
        make(code: "INVALID_ARGUMENTS", message: message)
    }

    /// Create an error response for unsupported environment.
    public static func unsupportedEnvironment(_ message: String) -> ErrorResponse {
        make(code: "UNSUPPORTED_ENVIRONMENT", message: message)
    }

    /// Create an error response for unavailable model.
    public static func unavailableModel(_ message: String) -> ErrorResponse {
        make(code: "UNAVAILABLE_MODEL", message: message)
    }

    /// Create an error response for generation failure.
    public static func generationFailure(_ message: String) -> ErrorResponse {
        make(code: "GENERATION_FAILURE", message: message)
    }

    /// Create an error response for internal errors.
    public static func internalError(_ message: String) -> ErrorResponse {
        make(code: "INTERNAL_ERROR", message: message)
    }
}
