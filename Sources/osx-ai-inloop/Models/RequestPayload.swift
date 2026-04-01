// RequestPayload.swift
// Codable struct representing the JSON request payload accepted via stdin.

import Foundation

/// The request payload that can be provided via stdin as JSON.
/// All fields are optional to allow partial requests merged with CLI flags.
///
/// Example JSON:
/// ```json
/// {
///   "prompt": "Explain async/await in Swift",
///   "system": "You are a Swift expert. Be concise.",
///   "input": "Here is the code context: ...",
///   "model": "on-device",
///   "format": "json",
///   "stream": false
/// }
/// ```
public struct RequestPayload: Codable, Sendable {
    /// The main prompt / user message.
    public var prompt: String?

    /// Optional system instruction / persona for the model session.
    public var system: String?

    /// Optional additional input text, appended to the prompt.
    public var input: String?

    /// Model mode: "on-device" (default) or "auto".
    public var model: String?

    /// Output format: "json" (default) or "text".
    public var format: String?

    /// Whether to stream the response. Defaults to false.
    public var stream: Bool?

    public init(
        prompt: String? = nil,
        system: String? = nil,
        input: String? = nil,
        model: String? = nil,
        format: String? = nil,
        stream: Bool? = nil
    ) {
        self.prompt = prompt
        self.system = system
        self.input = input
        self.model = model
        self.format = format
        self.stream = stream
    }

    // MARK: - Coding Keys

    enum CodingKeys: String, CodingKey {
        case prompt
        case system
        case input
        case model
        case format
        case stream
    }

    // MARK: - Validation

    /// Returns true if the payload has a non-empty prompt.
    public var hasPrompt: Bool {
        guard let p = prompt else { return false }
        return !p.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    /// Returns the effective prompt, trimmed of whitespace.
    public var effectivePrompt: String? {
        guard let p = prompt else { return nil }
        let trimmed = p.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    /// Merges another payload into this one. The `other` values take precedence where non-nil.
    public func merged(withOverrides other: RequestPayload) -> RequestPayload {
        RequestPayload(
            prompt: other.prompt ?? self.prompt,
            system: other.system ?? self.system,
            input: other.input ?? self.input,
            model: other.model ?? self.model,
            format: other.format ?? self.format,
            stream: other.stream ?? self.stream
        )
    }
}

// MARK: - CustomStringConvertible

extension RequestPayload: CustomStringConvertible {
    public var description: String {
        "RequestPayload(prompt: \(prompt ?? "nil"), model: \(model ?? "nil"), format: \(format ?? "nil"))"
    }
}
