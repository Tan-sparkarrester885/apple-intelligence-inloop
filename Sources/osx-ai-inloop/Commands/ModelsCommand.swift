// ModelsCommand.swift
// Lists available model modes and their status.

import ArgumentParser
import Foundation

#if canImport(FoundationModels)
import FoundationModels
#endif

struct ModelsCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "models",
        abstract: "List available model modes and their current status.",
        discussion: """
        Shows the available model selection modes for the --model flag.
        Checks the live availability status of each model mode.

        EXAMPLES:
          osx-ai-inloop models
          osx-ai-inloop models --json
        """
    )

    @Flag(name: .long, help: "Output as JSON to stdout.")
    var json: Bool = false

    func run() async throws {
        let modes = ModelModeInfo.all()

        if json {
            struct ModelsOutput: Encodable {
                let models: [ModelModeInfo]
                let defaultModel: String

                enum CodingKeys: String, CodingKey {
                    case models
                    case defaultModel = "default_model"
                }
            }
            let output = ModelsOutput(models: modes, defaultModel: "on-device")
            writeJSONStdout(output)
        } else {
            writeStderr("Available model modes:")
            writeStderr("")
            for modeInfo in modes {
                let defaultTag = modeInfo.identifier == "on-device" ? " (default)" : ""
                writeStderr("  \(modeInfo.identifier)\(defaultTag)")
                writeStderr("    Status:      \(modeInfo.status)")
                writeStderr("    Description: \(modeInfo.description)")
                writeStderr("")
            }
        }
    }
}

// MARK: - ModelModeInfo

/// Info struct for a model mode, used in the models command.
struct ModelModeInfo: Encodable {
    let identifier: String
    let status: String
    let description: String
    let isAvailable: Bool

    enum CodingKeys: String, CodingKey {
        case identifier
        case status
        case description
        case isAvailable = "is_available"
    }

    /// Returns information for all known model modes.
    static func all() -> [ModelModeInfo] {
        #if canImport(FoundationModels)
        let availability = SystemLanguageModel.default.availability
        let isAvailable: Bool
        let statusMessage: String
        switch availability {
        case .available:
            isAvailable = true
            statusMessage = "Available"
        case .unavailable(let reason):
            isAvailable = false
            switch reason {
            case .deviceNotEligible:
                statusMessage = "Unavailable (device not eligible for Apple Intelligence)"
            case .appleIntelligenceNotEnabled:
                statusMessage = "Unavailable (Apple Intelligence not enabled in System Settings)"
            case .modelNotReady:
                statusMessage = "Unavailable (model still downloading)"
            @unknown default:
                statusMessage = "Unavailable (unknown reason)"
            }
        @unknown default:
            isAvailable = false
            statusMessage = "Unknown"
        }
        return [
            ModelModeInfo(
                identifier: "on-device",
                status: statusMessage,
                description: "Apple on-device language model (~3B parameters). Privacy-preserving, no network calls.",
                isAvailable: isAvailable
            ),
            ModelModeInfo(
                identifier: "auto",
                status: statusMessage,
                description: "Automatically selects the best available model. Currently resolves to on-device.",
                isAvailable: isAvailable
            )
        ]
        #else
        return [
            ModelModeInfo(
                identifier: "on-device",
                status: "Unavailable (FoundationModels framework not present on this platform)",
                description: "Apple on-device language model (~3B parameters). Privacy-preserving, no network calls.",
                isAvailable: false
            ),
            ModelModeInfo(
                identifier: "auto",
                status: "Unavailable (FoundationModels framework not present on this platform)",
                description: "Automatically selects the best available model. Currently resolves to on-device.",
                isAvailable: false
            )
        ]
        #endif
    }
}
