// FoundationModelEngine.swift
// Real implementation of ModelEngine using Apple's FoundationModels framework.
// Guarded with #if canImport(FoundationModels) to allow compilation on non-macOS 26 systems.

import Foundation

#if canImport(FoundationModels)
import FoundationModels

/// Production engine that uses Apple's on-device Foundation Models.
/// Requires macOS 26+ with Apple Intelligence enabled.
public struct FoundationModelEngine: ModelEngine {

    public init() {}

    public func generate(
        prompt: String,
        systemInstruction: String?,
        inputText: String?,
        options: GenerationOptions?
    ) async throws -> GenerationResult {

        // Verify model availability before attempting generation
        let availability = SystemLanguageModel.default.availability
        switch availability {
        case .available:
            break // Continue
        case .unavailable(let reason):
            let reasonMessage: String
            switch reason {
            case .deviceNotEligible:
                reasonMessage = "This device is not eligible for Apple Intelligence. Requires Apple Silicon (M-series)."
            case .appleIntelligenceNotEnabled:
                reasonMessage = "Apple Intelligence is not enabled. Enable it in System Settings > Apple Intelligence & Siri."
            case .modelNotReady:
                reasonMessage = "The Apple Intelligence model is still downloading. Please try again later."
            @unknown default:
                reasonMessage = "Apple Intelligence is unavailable for an unknown reason."
            }
            throw GenerationEngineError.modelUnavailable(reason: reasonMessage)
        @unknown default:
            throw GenerationEngineError.modelUnavailable(reason: "Apple Intelligence availability is unknown.")
        }

        // Build the effective prompt text (combine prompt + optional input)
        let fullPrompt: String
        if let inputText = inputText, !inputText.isEmpty {
            fullPrompt = "\(prompt)\n\n\(inputText)"
        } else {
            fullPrompt = prompt
        }

        // Create the session with optional system instructions.
        // LanguageModelSession uses an InstructionsBuilder closure for instructions.
        let session: LanguageModelSession
        if let systemInstruction = systemInstruction, !systemInstruction.isEmpty {
            session = LanguageModelSession(model: SystemLanguageModel.default) {
                systemInstruction
            }
        } else {
            session = LanguageModelSession(model: SystemLanguageModel.default)
        }

        // Record start time for usage metadata
        let startTime = Date()

        // Perform the generation
        do {
            let response = try await session.respond(to: fullPrompt)
            let durationSeconds = Date().timeIntervalSince(startTime)

            let usage = UsageInfo(durationSeconds: durationSeconds)
            return GenerationResult(
                output: response.content,
                model: "on-device",
                usage: usage
            )
        } catch let error as LanguageModelSession.GenerationError {
            let message = describeGenerationError(error)
            throw GenerationEngineError.generationFailed(underlying: message)
        } catch {
            throw GenerationEngineError.generationFailed(underlying: error.localizedDescription)
        }
    }

    // MARK: - Private Helpers

    /// Convert a LanguageModelSession.GenerationError to a human-readable string.
    private func describeGenerationError(_ error: LanguageModelSession.GenerationError) -> String {
        // LanguageModelSession.GenerationError is an enum — we handle known cases
        // and fall back to localizedDescription for future cases.
        switch error {
        default:
            return "Generation failed: \(error.localizedDescription)"
        }
    }
}

#else

// MARK: - Stub Implementation (Non-macOS 26 platforms)

/// Stub engine that throws an appropriate error when FoundationModels is not available.
/// This stub enables compilation and testing on macOS < 26 or non-Apple platforms.
public struct FoundationModelEngine: ModelEngine {

    public init() {}

    public func generate(
        prompt: String,
        systemInstruction: String?,
        inputText: String?,
        options: GenerationOptions?
    ) async throws -> GenerationResult {
        throw GenerationEngineError.frameworkUnavailable
    }
}

#endif
