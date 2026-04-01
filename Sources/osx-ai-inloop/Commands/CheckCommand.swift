// CheckCommand.swift
// Runs environment and capability checks, reporting on Apple Intelligence availability.

import ArgumentParser
import Foundation

struct CheckCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "check",
        abstract: "Check environment compatibility and Apple Intelligence availability.",
        discussion: """
        Verifies that the current system meets all requirements for running Apple's Foundation Models:
          - macOS 26.0 or later
          - Apple Silicon (M-series) processor
          - Apple Intelligence enabled in System Settings
          - Foundation model downloaded and ready

        Use --json to get machine-readable output for scripting.

        EXAMPLES:
          osx-ai-inloop check
          osx-ai-inloop check --json
          osx-ai-inloop check --json | jq '.is_compatible'
        """
    )

    @Flag(name: .long, help: "Output results as JSON to stdout instead of human-readable text on stderr.")
    var json: Bool = false

    @Flag(name: .long, help: "Suppress informational messages; only output results.")
    var quiet: Bool = false

    func run() async throws {
        if !quiet && !json {
            writeStderr("Running environment checks...")
            writeStderr("")
        }

        let result = await EnvironmentChecker.run()

        if json {
            // Machine-readable JSON to stdout
            writeJSONStdout(result.toJSON())
        } else {
            // Human-readable to stderr
            writeStderr(result.toHumanReadable())
        }

        // Exit with non-zero code if not compatible
        if !result.isCompatible {
            throw ExitCode(rawValue: AppExitCode.unsupportedEnvironment.rawValue)
        }
    }
}
