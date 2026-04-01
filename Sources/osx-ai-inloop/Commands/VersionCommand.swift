// VersionCommand.swift
// Prints the version string for osx-ai-inloop.

import ArgumentParser
import Foundation

struct VersionCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "version",
        abstract: "Print the version number of osx-ai-inloop."
    )

    @Flag(name: .long, help: "Output version as JSON.")
    var json: Bool = false

    func run() async throws {
        if json {
            struct VersionOutput: Encodable {
                let version: String
                let major: Int
                let minor: Int
                let patch: Int
            }
            let output = VersionOutput(
                version: AppVersion.string,
                major: AppVersion.major,
                minor: AppVersion.minor,
                patch: AppVersion.patch
            )
            writeJSONStdout(output)
        } else {
            writeStdout("osx-ai-inloop \(AppVersion.string)")
        }
    }
}
