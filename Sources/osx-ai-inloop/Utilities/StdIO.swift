// StdIO.swift
// Helper functions for reading/writing standard I/O streams.
// Uses FileHandle directly for precise control over stdout/stderr.

import Foundation

// MARK: - stdout

/// Write a string to stdout followed by a newline.
/// Uses FileHandle.standardOutput for direct byte-level writes.
public func writeStdout(_ text: String) {
    var output = text + "\n"
    if let data = output.data(using: .utf8) {
        FileHandle.standardOutput.write(data)
    }
}

/// Write a string to stdout without a trailing newline.
public func writeStdoutRaw(_ text: String) {
    if let data = text.data(using: .utf8) {
        FileHandle.standardOutput.write(data)
    }
}

/// Encode a Codable value as pretty-printed JSON and write it to stdout.
/// Falls back to a JSON error response if encoding fails.
public func writeJSONStdout<T: Encodable>(_ value: T) {
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    // Use snake_case for consistent JSON keys
    // Note: we do NOT use .convertToSnakeCase here as our structs use explicit CodingKeys

    do {
        let data = try encoder.encode(value)
        if let json = String(data: data, encoding: .utf8) {
            writeStdout(json)
        }
    } catch {
        // If encoding fails, write a plain error JSON
        let fallback = """
        {
          "ok": false,
          "error": {
            "code": "INTERNAL_ERROR",
            "message": "Failed to encode response: \(error.localizedDescription)"
          }
        }
        """
        writeStdout(fallback)
    }
}

// MARK: - stderr

/// Write a string to stderr followed by a newline.
public func writeStderr(_ text: String) {
    let output = text + "\n"
    if let data = output.data(using: .utf8) {
        FileHandle.standardError.write(data)
    }
}

/// Write a string to stderr without a trailing newline.
public func writeStderrRaw(_ text: String) {
    if let data = text.data(using: .utf8) {
        FileHandle.standardError.write(data)
    }
}

// MARK: - stdin

/// Read all available content from stdin.
///
/// Returns nil if stdin is a terminal (interactive TTY) with no data.
/// Returns an empty string if stdin is a pipe/file but empty.
/// Returns the full content string if stdin has data.
public func readStdin() -> String? {
    // Check if stdin is a pipe/file (not a terminal)
    guard !isStdinTTY() else {
        return nil
    }

    // Read all available data from stdin
    let data = FileHandle.standardInput.readDataToEndOfFile()
    guard !data.isEmpty else {
        return nil
    }

    return String(data: data, encoding: .utf8)
}

/// Read a single line from stdin (blocking).
/// Returns nil if stdin is a TTY or if EOF is reached.
public func readStdinLine() -> String? {
    guard !isStdinTTY() else { return nil }
    return readLine(strippingNewline: true)
}

/// Returns true if stdin is connected to a terminal (interactive TTY).
/// Returns false if stdin is a pipe or redirected file.
private func isStdinTTY() -> Bool {
    #if canImport(Darwin)
    return isatty(STDIN_FILENO) != 0
    #else
    // On non-Darwin platforms, attempt a stat-based check
    var s = stat()
    if fstat(STDIN_FILENO, &s) == 0 {
        // S_IFIFO = pipe, S_IFREG = regular file
        let mode = s.st_mode
        let isFifo = (mode & S_IFMT) == S_IFIFO
        let isRegular = (mode & S_IFMT) == S_IFREG
        return !isFifo && !isRegular
    }
    return true
    #endif
}

// MARK: - JSON Helpers

/// Parse JSON data into a Decodable type. Returns nil on failure.
public func decodeJSON<T: Decodable>(_ data: Data, as type: T.Type) -> T? {
    try? JSONDecoder().decode(type, from: data)
}

/// Encode a value to a pretty-printed JSON string. Returns nil on failure.
public func encodeJSONString<T: Encodable>(_ value: T) -> String? {
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    guard let data = try? encoder.encode(value) else { return nil }
    return String(data: data, encoding: .utf8)
}
