// MockModelEngine.swift
// Mock implementation of ModelEngine for use in unit tests.
// Allows configuring fixed responses or error conditions.

import Foundation

// MARK: - MockModelEngine

/// A mock model engine for use in unit tests and local development.
/// Configurable to return fixed responses, simulate errors, or apply custom logic.
public final class MockModelEngine: ModelEngine, @unchecked Sendable {

    // MARK: - Configuration

    /// The fixed response to return for any prompt.
    public var fixedResponse: String

    /// The model name to report in results.
    public var modelName: String

    /// If set, throw this error instead of returning a result.
    public var errorToThrow: Error?

    /// Optional custom handler — if set, called instead of fixed response logic.
    public var customHandler: ((String, String?, String?, GenerationOptions?) async throws -> GenerationResult)?

    /// Number of times `generate` has been called.
    public private(set) var callCount: Int = 0

    /// The last prompt passed to `generate`.
    public private(set) var lastPrompt: String?

    /// The last system instruction passed to `generate`.
    public private(set) var lastSystemInstruction: String?

    /// The last input text passed to `generate`.
    public private(set) var lastInputText: String?

    // MARK: - Initialization

    /// Create a mock engine with a fixed response string.
    public init(
        fixedResponse: String = "Mock response text.",
        modelName: String = "mock",
        errorToThrow: Error? = nil
    ) {
        self.fixedResponse = fixedResponse
        self.modelName = modelName
        self.errorToThrow = errorToThrow
    }

    // MARK: - ModelEngine

    public func generate(
        prompt: String,
        systemInstruction: String?,
        inputText: String?,
        options: GenerationOptions?
    ) async throws -> GenerationResult {
        callCount += 1
        lastPrompt = prompt
        lastSystemInstruction = systemInstruction
        lastInputText = inputText

        // Use custom handler if provided
        if let handler = customHandler {
            return try await handler(prompt, systemInstruction, inputText, options)
        }

        // Throw configured error if set
        if let error = errorToThrow {
            throw error
        }

        // Return the fixed response
        return GenerationResult(
            output: fixedResponse,
            model: modelName,
            usage: UsageInfo(durationSeconds: 0.001)
        )
    }

    // MARK: - Reset

    /// Reset all tracking state for re-use between tests.
    public func reset() {
        callCount = 0
        lastPrompt = nil
        lastSystemInstruction = nil
        lastInputText = nil
        errorToThrow = nil
        customHandler = nil
    }
}

// MARK: - Preset Factory Methods

extension MockModelEngine {
    /// Creates a mock that simulates a model unavailable error.
    public static func unavailable(reason: String = "Mock: model unavailable") -> MockModelEngine {
        MockModelEngine(errorToThrow: GenerationEngineError.modelUnavailable(reason: reason))
    }

    /// Creates a mock that simulates a generation failure.
    public static func failing(reason: String = "Mock: generation failed") -> MockModelEngine {
        MockModelEngine(errorToThrow: GenerationEngineError.generationFailed(underlying: reason))
    }

    /// Creates a mock that echoes the prompt back as the response.
    public static func echoEngine() -> MockModelEngine {
        let engine = MockModelEngine()
        engine.customHandler = { prompt, _, _, _ in
            GenerationResult(output: "Echo: \(prompt)", model: "mock-echo")
        }
        return engine
    }
}
