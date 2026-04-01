// main.swift
// Entry point for the osx-ai-inloop CLI.
// Apple Intelligence Inloop — Unix-friendly wrapper for Apple's Foundation Models.

import ArgumentParser
import Foundation

// Configure signal handling before launching the CLI.
// Ignoring SIGPIPE prevents crashes when piped to consumers that close early.
configureSIGPIPE()

// MARK: - Root Command

// Root command — ArgumentParser dispatches to subcommands based on the first CLI argument.
// AsyncParsableCommand enables async run() methods in subcommands.
struct OsxAiInloop: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "osx-ai-inloop",
        abstract: "Apple Intelligence Inloop — Unix-friendly CLI wrapper for Apple's Foundation Models.",
        discussion: """
        A scriptable command-line interface to Apple's on-device language models (macOS 26+).
        Accepts prompts via stdin (JSON or plain text) or via --prompt flag.
        Outputs structured JSON responses by default, making it ideal for shell scripts,
        Ruby automation via Open3, and JXA workflows.

        REQUIREMENTS:
          macOS 26+, Apple Silicon (M-series), Apple Intelligence enabled in System Settings.

        EXAMPLES:
          echo '{"prompt":"Explain async/await in Swift"}' | osx-ai-inloop
          osx-ai-inloop generate --prompt "Hello, world" --format text
          osx-ai-inloop check
          osx-ai-inloop models
        """,
        version: AppVersion.string,
        subcommands: [
            GenerateCommand.self,
            CheckCommand.self,
            ModelsCommand.self,
            VersionCommand.self
        ],
        defaultSubcommand: GenerateCommand.self
    )
}

// MARK: - Version Constants

/// Application version constants.
enum AppVersion {
    static let string = "0.1.0"
    static let major = 0
    static let minor = 1
    static let patch = 0
}

// MARK: - Launch

OsxAiInloop.main()
