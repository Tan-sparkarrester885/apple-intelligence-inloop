// main.swift
// The executable entry point for osx-ai-inloop.
// This file must be named "main.swift" (lowercase) to be the top-level entry point
// in a Swift Package Manager executable target.

import Foundation

// Configure signal handling before launching the CLI.
// Ignoring SIGPIPE prevents crashes when piped to consumers that close early.
configureSIGPIPE()

// Launch the root ArgumentParser command via Task so the async overload from
// AsyncParsableCommand is called (not the synchronous ParsableCommand.main()).
// ArgumentParser only calls exit() on error, not on success, so we explicitly
// call exit(0) after main() returns. RunLoop.main.run() keeps the thread alive
// until one of those exit() calls fires.
Task {
    await OsxAiInloop.main()
    Darwin.exit(0)
}
RunLoop.main.run()
