// main.swift
// The executable entry point for osx-ai-inloop.
// This file must be named "main.swift" (lowercase) to be the top-level entry point
// in a Swift Package Manager executable target.

import Foundation

// Configure signal handling before launching the CLI.
// Ignoring SIGPIPE prevents crashes when piped to consumers that close early.
configureSIGPIPE()

// Launch the root ArgumentParser command.
// OsxAiInloop dispatches to the appropriate subcommand based on CLI arguments.
OsxAiInloop.main()
