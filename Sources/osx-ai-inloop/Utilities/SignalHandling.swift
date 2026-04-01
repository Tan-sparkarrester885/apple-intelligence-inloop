// SignalHandling.swift
// Global signal configuration for the osx-ai-inloop process.
// This file configures signal handling at startup to ensure graceful behavior
// when the process is used in pipelines.

#if canImport(Darwin)
import Darwin

/// Configure signal handling for the osx-ai-inloop process.
/// Call this before running the main command.
func configureSIGPIPE() {
    // Ignore SIGPIPE so the process doesn't crash when writing to a closed pipe.
    // This is common when piping to tools like `head`, `grep`, or any consumer
    // that may close their end of the pipe before we finish writing.
    // Without this, writing to a closed stdout/stderr raises SIGPIPE and kills the process.
    signal(SIGPIPE, SIG_IGN)
}
#else
func configureSIGPIPE() {
    // Not needed on non-Darwin platforms
}
#endif
