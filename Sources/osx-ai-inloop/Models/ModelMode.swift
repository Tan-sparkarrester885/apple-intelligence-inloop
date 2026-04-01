// ModelMode.swift
// Enum representing the available model selection modes.

import Foundation

/// Represents the model selection mode for inference.
/// Maps CLI string values to typed cases.
public enum ModelMode: String, CaseIterable, Sendable {
    /// Use Apple's on-device language model (default).
    /// Privacy-preserving: no network calls, all processing on-device.
    case onDevice = "on-device"

    /// Automatically select the best available model.
    /// Currently resolves to on-device inference.
    case auto = "auto"

    // MARK: - Initialization

    /// Initialize from a CLI string value (case-insensitive).
    public init?(cliValue: String) {
        let normalized = cliValue.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        if let mode = ModelMode(rawValue: normalized) {
            self = mode
        } else {
            return nil
        }
    }

    // MARK: - Validation

    /// Validate a string value and return the corresponding ModelMode.
    /// Throws a descriptive error if the value is not recognized.
    public static func validate(_ value: String) throws -> ModelMode {
        guard let mode = ModelMode(cliValue: value) else {
            let valid = ModelMode.allCases.map { "\"\($0.rawValue)\"" }.joined(separator: ", ")
            throw ModelModeError.unknownMode(value: value, validModes: valid)
        }
        return mode
    }

    // MARK: - Properties

    /// Human-readable display name.
    public var displayName: String {
        switch self {
        case .onDevice: return "On-Device"
        case .auto: return "Auto"
        }
    }

    /// Description of this model mode.
    public var description: String {
        switch self {
        case .onDevice:
            return "Apple on-device language model (~3B parameters). No network calls, privacy-preserving."
        case .auto:
            return "Automatically selects the best available model. Currently resolves to on-device."
        }
    }

    /// Whether this mode requires network access.
    public var requiresNetwork: Bool {
        switch self {
        case .onDevice: return false
        case .auto: return false
        }
    }

    /// Whether this mode supports streaming responses.
    public var supportsStreaming: Bool {
        switch self {
        case .onDevice: return true
        case .auto: return true
        }
    }
}

// MARK: - ModelModeError

/// Errors thrown when validating model mode strings.
public enum ModelModeError: Error, CustomStringConvertible {
    case unknownMode(value: String, validModes: String)

    public var description: String {
        switch self {
        case .unknownMode(let value, let validModes):
            return "Unknown model mode '\(value)'. Valid modes are: \(validModes)"
        }
    }

    public var localizedDescription: String { description }
}

// MARK: - Codable

extension ModelMode: Codable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let raw = try container.decode(String.self)
        if let mode = ModelMode(cliValue: raw) {
            self = mode
        } else {
            let valid = ModelMode.allCases.map { $0.rawValue }.joined(separator: ", ")
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Unknown model mode '\(raw)'. Expected one of: \(valid)"
            )
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }
}
