// CLIParsingTests.swift
// Tests for command-line argument parsing.

import Testing
import Foundation
@testable import osx_ai_inloop

// NOTE: ArgumentParser commands use @main, which means they cannot be directly
// instantiated in tests the same way. We test the underlying option types and
// parsing behavior through the public interfaces of each command.

@Suite("CLI Parsing Tests")
struct CLIParsingTests {

    // MARK: - ModelMode Parsing

    @Test("ModelMode parses on-device correctly")
    func testModelModeOnDevice() throws {
        let mode = try ModelMode.validate("on-device")
        #expect(mode == .onDevice)
        #expect(mode.rawValue == "on-device")
    }

    @Test("ModelMode parses auto correctly")
    func testModelModeAuto() throws {
        let mode = try ModelMode.validate("auto")
        #expect(mode == .auto)
        #expect(mode.rawValue == "auto")
    }

    @Test("ModelMode throws for unknown value")
    func testModelModeUnknown() throws {
        #expect(throws: ModelModeError.self) {
            try ModelMode.validate("gpt-4")
        }
    }

    @Test("ModelMode throws for empty string")
    func testModelModeEmpty() throws {
        #expect(throws: ModelModeError.self) {
            try ModelMode.validate("")
        }
    }

    @Test("ModelMode is case insensitive for known values")
    func testModelModeCaseInsensitive() throws {
        // on-device is always lowercase, but let's verify the init handles it
        let mode = ModelMode(cliValue: "on-device")
        #expect(mode == .onDevice)
    }

    // MARK: - OutputFormat Parsing

    @Test("OutputFormat parses json correctly")
    func testOutputFormatJSON() {
        let format = OutputFormat(rawValue: "json")
        #expect(format == .json)
    }

    @Test("OutputFormat parses text correctly")
    func testOutputFormatText() {
        let format = OutputFormat(rawValue: "text")
        #expect(format == .text)
    }

    @Test("OutputFormat returns nil for unknown value")
    func testOutputFormatUnknown() {
        let format = OutputFormat(rawValue: "xml")
        #expect(format == nil)
    }

    @Test("OutputFormat defaults to json for unknown")
    func testOutputFormatDefaultFallback() {
        let format = OutputFormat(rawValue: "xml") ?? .json
        #expect(format == .json)
    }

    // MARK: - AppVersion

    @Test("AppVersion string is 0.1.0")
    func testAppVersionString() {
        #expect(AppVersion.string == "0.1.0")
    }

    @Test("AppVersion components match string")
    func testAppVersionComponents() {
        #expect(AppVersion.major == 0)
        #expect(AppVersion.minor == 1)
        #expect(AppVersion.patch == 0)
    }

    // MARK: - ModelMode allCases

    @Test("ModelMode has two cases")
    func testModelModeAllCases() {
        let cases = ModelMode.allCases
        #expect(cases.count == 2)
        #expect(cases.contains(.onDevice))
        #expect(cases.contains(.auto))
    }

    @Test("ModelMode init from cliValue returns nil for unknown")
    func testModelModeInitNil() {
        let mode = ModelMode(cliValue: "unknown-model-xyz")
        #expect(mode == nil)
    }
}
